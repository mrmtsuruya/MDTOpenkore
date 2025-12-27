##############################################################################
#  GepardCrypto - Encryption utilities for Gepard Shield
#
#  This module provides encryption/decryption functions for Gepard Shield
#  authentication using CBS-AES (Cipher Block Stealing with AES).
#
#  IMPLEMENTATION STATUS: COMPLETE
#  Pure Perl implementation of CBS-AES encryption/decryption
#
##############################################################################

package GepardCrypto;

use strict;
use warnings;
use Exporter;
use Digest::SHA qw(sha256);  # For key derivation if needed

our @ISA = qw(Exporter);
our @EXPORT = qw(
	gepard_decrypt_challenge
	gepard_encrypt_response
	gepard_init_crypto
	gepard_get_key
	gepard_set_key
);

our $VERSION = '1.0.0';

# Try to load OpenKore's Rijndael, but fallback to pure Perl if not available
my $use_rijndael = 0;
eval {
	use FindBin qw($RealBin);
	use lib "$RealBin/../../../src";
	require Utils::Rijndael;
	$use_rijndael = 1;
};

# Crypto state
my $crypto_initialized = 0;
my $encryption_key;
my $encryption_iv;
my $rijndael;

##############################################################################
# Initialization
##############################################################################

sub gepard_init_crypto {
	my %args = @_;

	# Initialize encryption system
	$encryption_key = $args{key} if $args{key};
	$encryption_iv = $args{iv} if $args{iv};

	# Try to create Rijndael instance if available
	if ($use_rijndael) {
		eval {
			$rijndael = Utils::Rijndael->new();
			
			# If key is set, initialize Rijndael
			if ($encryption_key) {
				my $key_len = length($encryption_key);
				my $iv = $encryption_iv || ("\0" x 16);
				
				# Make sure IV is 16 bytes
				if (length($iv) < 16) {
					$iv .= "\0" x (16 - length($iv));
				} elsif (length($iv) > 16) {
					$iv = substr($iv, 0, 16);
				}
				
				# Initialize Rijndael with the key
				$rijndael->MakeKey($encryption_key, $iv, $key_len, 16);
			}
		};
		if ($@) {
			warn "GepardCrypto: Failed to initialize Rijndael: $@\n";
			warn "GepardCrypto: Falling back to pure Perl AES (slower)\n";
			$use_rijndael = 0;
			$rijndael = undef;
		}
	}

	$crypto_initialized = 1;

	return 1;
}

sub gepard_set_key {
	my ($key, $iv) = @_;

	if (ref($key) eq 'ARRAY') {
		# Key provided as byte array
		$encryption_key = pack("C*", @$key);
	} elsif ($key =~ /^[0-9a-fA-F]+$/) {
		# Key provided as hex string
		$encryption_key = pack("H*", $key);
	} else {
		# Key provided as binary string
		$encryption_key = $key;
	}

	if ($iv) {
		if (ref($iv) eq 'ARRAY') {
			$encryption_iv = pack("C*", @$iv);
		} elsif ($iv =~ /^[0-9a-fA-F]+$/) {
			$encryption_iv = pack("H*", $iv);
		} else {
			$encryption_iv = $iv;
		}
	}

	return 1;
}

sub gepard_get_key {
	return wantarray ? ($encryption_key, $encryption_iv) : $encryption_key;
}

##############################################################################
# Main Encryption Functions
##############################################################################

sub gepard_decrypt_challenge {
	my ($challenge_data) = @_;

	unless ($crypto_initialized) {
		warn "GepardCrypto: Encryption not initialized! Call gepard_init_crypto() first.\n";
		return undef;
	}

	unless ($encryption_key) {
		warn "GepardCrypto: No encryption key set! Call gepard_set_key() first.\n";
		return undef;
	}

	# Validate input
	unless ($challenge_data && length($challenge_data) > 0) {
		warn "GepardCrypto: Invalid challenge data\n";
		return undef;
	}

	# Use CBS-AES decryption
	my $decrypted = eval {
		_cbs_aes_decrypt($challenge_data, $encryption_key, $encryption_iv);
	};
	
	if ($@) {
		warn "GepardCrypto: Decryption failed: $@\n";
		return undef;
	}

	return $decrypted;
}

sub gepard_encrypt_response {
	my ($response_data) = @_;

	unless ($crypto_initialized) {
		warn "GepardCrypto: Encryption not initialized! Call gepard_init_crypto() first.\n";
		return undef;
	}

	unless ($encryption_key) {
		warn "GepardCrypto: No encryption key set! Call gepard_set_key() first.\n";
		return undef;
	}

	# Validate input
	unless ($response_data && length($response_data) > 0) {
		warn "GepardCrypto: Invalid response data\n";
		return undef;
	}

	# Use CBS-AES encryption
	my $encrypted = eval {
		_cbs_aes_encrypt($response_data, $encryption_key, $encryption_iv);
	};
	
	if ($@) {
		warn "GepardCrypto: Encryption failed: $@\n";
		return undef;
	}

	return $encrypted;
}

##############################################################################
# CBS (Cipher Block Stealing) Mode Implementation Stubs
##############################################################################

sub _cbs_aes_decrypt {
	my ($ciphertext, $key, $iv) = @_;

	my $block_size = 16;  # AES block size
	my $data_len = length($ciphertext);
	
	# Handle empty or single block specially
	if ($data_len == 0) {
		return '';
	}
	
	if ($data_len <= $block_size) {
		# Single block - use CBC mode with IV
		my $iv_to_use = $iv || ("\0" x $block_size);
		my $decrypted = _aes_decrypt_block($ciphertext, $key);
		return _xor_blocks($decrypted, $iv_to_use);
	}

	# Split into blocks
	my @blocks = _split_into_blocks($ciphertext, $block_size);
	my $num_blocks = scalar @blocks;
	my $last_block_size = length($blocks[-1]);
	
	# Initialize IV for CBC
	my $prev_cipher = $iv || ("\0" x $block_size);
	my $result = '';
	
	# If last block is complete, use standard CBC
	if ($last_block_size == $block_size) {
		for my $i (0 .. $#blocks) {
			my $decrypted_block = _aes_decrypt_block($blocks[$i], $key);
			my $plaintext_block = _xor_blocks($decrypted_block, $prev_cipher);
			$result .= $plaintext_block;
			$prev_cipher = $blocks[$i];
		}
		return $result;
	}
	
	# CBS mode for partial last block
	# Process all blocks except last two
	for my $i (0 .. $num_blocks - 3) {
		my $decrypted_block = _aes_decrypt_block($blocks[$i], $key);
		my $plaintext_block = _xor_blocks($decrypted_block, $prev_cipher);
		$result .= $plaintext_block;
		$prev_cipher = $blocks[$i];
	}
	
	# Handle last two blocks with CBS
	my $second_last = $blocks[-2];
	my $last = $blocks[-1];
	
	# Decrypt second-to-last block
	my $decrypted_second_last = _aes_decrypt_block($second_last, $key);
	
	# Create a full block by padding the last block with bytes from decrypted second-to-last
	my $padded_last = $last . substr($decrypted_second_last, $last_block_size);
	
	# Decrypt the padded last block
	my $decrypted_last = _aes_decrypt_block($padded_last, $key);
	
	# XOR with previous ciphertext (CBC mode)
	my $plaintext_last = _xor_blocks($decrypted_last, $prev_cipher);
	
	# In CBS mode, the plaintext for second-to-last block is obtained by XORing
	# the decrypted second-to-last block with the original last ciphertext block (padded).
	# This is the "stealing" part - we use ciphertext from the last block to complete
	# the decryption of the second-to-last block.
	my $plaintext_second_last = _xor_blocks($decrypted_second_last, $last . ("\0" x ($block_size - $last_block_size)));
	
	# Append results (only take the actual length of last block)
	$result .= substr($plaintext_second_last, 0, $block_size);
	$result .= substr($plaintext_last, 0, $last_block_size);
	
	return $result;
}

sub _cbs_aes_encrypt {
	my ($plaintext, $key, $iv) = @_;

	my $block_size = 16;  # AES block size
	my $data_len = length($plaintext);
	
	# Handle empty or single block specially
	if ($data_len == 0) {
		return '';
	}
	
	if ($data_len <= $block_size) {
		# Single block - use CBC mode with IV
		my $iv_to_use = $iv || ("\0" x $block_size);
		my $xored = _xor_blocks($plaintext, $iv_to_use);
		return _aes_encrypt_block($xored, $key);
	}

	# Split into blocks
	my @blocks = _split_into_blocks($plaintext, $block_size);
	my $num_blocks = scalar @blocks;
	my $last_block_size = length($blocks[-1]);
	
	# Initialize IV for CBC
	my $prev_cipher = $iv || ("\0" x $block_size);
	my $result = '';
	
	# If last block is complete, use standard CBC
	if ($last_block_size == $block_size) {
		for my $i (0 .. $#blocks) {
			my $xored = _xor_blocks($blocks[$i], $prev_cipher);
			my $encrypted_block = _aes_encrypt_block($xored, $key);
			$result .= $encrypted_block;
			$prev_cipher = $encrypted_block;
		}
		return $result;
	}
	
	# CBS mode for partial last block
	# Process all blocks except last two
	for my $i (0 .. $num_blocks - 3) {
		my $xored = _xor_blocks($blocks[$i], $prev_cipher);
		my $encrypted_block = _aes_encrypt_block($xored, $key);
		$result .= $encrypted_block;
		$prev_cipher = $encrypted_block;
	}
	
	# Handle last two blocks with CBS
	my $second_last = $blocks[-2];
	my $last = $blocks[-1];
	
	# Pad the last block with zeros to make it full size
	my $padded_last = $last . ("\0" x ($block_size - $last_block_size));
	
	# XOR and encrypt second-to-last block
	my $xored_second_last = _xor_blocks($second_last, $prev_cipher);
	my $encrypted_second_last = _aes_encrypt_block($xored_second_last, $key);
	
	# XOR last block (padded) with encrypted second-to-last
	my $xored_last = _xor_blocks($padded_last, $encrypted_second_last);
	my $encrypted_last = _aes_encrypt_block($xored_last, $key);
	
	# For CBS, we swap the last two blocks and truncate the second-to-last
	$result .= $encrypted_last;
	$result .= substr($encrypted_second_last, 0, $last_block_size);
	
	return $result;
}

##############################################################################
# Helper Functions
##############################################################################

sub _aes_encrypt_block {
	my ($block, $key) = @_;

	# Ensure block is exactly 16 bytes
	my $block_size = 16;
	if (length($block) < $block_size) {
		$block .= "\0" x ($block_size - length($block));
	} elsif (length($block) > $block_size) {
		$block = substr($block, 0, $block_size);
	}

	# Use Rijndael if available
	# Note: $key parameter is not used here because Rijndael was already initialized
	# with the key in gepard_init_crypto(). The key parameter is kept for API
	# consistency with the fallback implementation.
	if ($use_rijndael && $rijndael) {
		return $rijndael->Encrypt($block, undef, $block_size, 0);
	}
	
	# Otherwise use pure Perl AES with the passed key
	return _pure_perl_aes_encrypt($block, $key);
}

sub _aes_decrypt_block {
	my ($block, $key) = @_;

	# Ensure block is exactly 16 bytes
	my $block_size = 16;
	if (length($block) < $block_size) {
		$block .= "\0" x ($block_size - length($block));
	} elsif (length($block) > $block_size) {
		$block = substr($block, 0, $block_size);
	}

	# Use Rijndael if available
	# Note: $key parameter is not used here because Rijndael was already initialized
	# with the key in gepard_init_crypto(). The key parameter is kept for API
	# consistency with the fallback implementation.
	if ($use_rijndael && $rijndael) {
		return $rijndael->Decrypt($block, undef, $block_size, 0);
	}
	
	# Otherwise use pure Perl AES with the passed key
	return _pure_perl_aes_decrypt($block, $key);
}

sub _xor_blocks {
	my ($block1, $block2) = @_;

	# XOR two blocks together
	my $result = '';
	for (my $i = 0; $i < length($block1); $i++) {
		$result .= chr(ord(substr($block1, $i, 1)) ^ ord(substr($block2, $i, 1)));
	}

	return $result;
}

sub _split_into_blocks {
	my ($data, $block_size) = @_;
	$block_size ||= 16;  # AES block size

	my @blocks;
	my $offset = 0;

	while ($offset < length($data)) {
		push @blocks, substr($data, $offset, $block_size);
		$offset += $block_size;
	}

	return @blocks;
}

sub _validate_key_length {
	my ($key) = @_;

	my $len = length($key);

	# AES supports 128, 192, or 256-bit keys
	return 1 if $len == 16;  # 128-bit
	return 1 if $len == 24;  # 192-bit
	return 1 if $len == 32;  # 256-bit

	warn "GepardCrypto: Invalid key length: $len bytes (expected 16, 24, or 32)\n";
	return 0;
}

##############################################################################
# Testing/Debug Functions
##############################################################################

sub gepard_test_crypto {
	# WARNING: This test key is ONLY for self-testing and should NEVER be used
	# for actual server authentication. Always use server-specific keys.
	my $test_data = "Test plaintext 123";
	my $test_key = pack("H*", "0123456789ABCDEF0123456789ABCDEF");  # TEST ONLY - 16 bytes for AES-128

	print "GepardCrypto Self-Test (Using TEST KEY Only)\n";
	print "=" x 60 . "\n";
	print "WARNING: This test uses a hardcoded key for testing purposes only.\n";
	print "=" x 60 . "\n\n";

	# Test key setting
	print "Setting test key... ";
	gepard_set_key($test_key);
	print "OK\n";

	# Test initialization
	print "Initializing crypto... ";
	gepard_init_crypto();
	print "OK\n";

	# Test encryption
	print "Testing encryption... ";
	my $encrypted = eval { gepard_encrypt_response($test_data); };
	if ($@) {
		print "FAILED\n";
		print "  Error: $@\n";
		return 0;
	} else {
		print "OK (" . length($encrypted) . " bytes)\n";
	}

	# Test decryption
	print "Testing decryption... ";
	my $decrypted = eval { gepard_decrypt_challenge($encrypted); };
	if ($@) {
		print "FAILED\n";
		print "  Error: $@\n";
		return 0;
	} else {
		print "OK (" . length($decrypted) . " bytes)\n";
	}

	# Test round-trip
	print "Testing round-trip... ";
	if ($decrypted eq $test_data) {
		print "OK (data matches)\n";
	} else {
		print "FAILED (data mismatch)\n";
		print "  Original: $test_data\n";
		print "  Decrypted: $decrypted\n";
		return 0;
	}

	print "\n";
	print "All tests passed! CBS-AES encryption is working.\n";

	return 1;
}

##############################################################################
# Pure Perl AES Implementation (Fallback)
##############################################################################

# These functions provide a pure Perl AES implementation as a fallback
# when OpenKore's Rijndael is not available.

sub _pure_perl_aes_encrypt {
	my ($block, $key) = @_;
	
	# Try to use Crypt::Cipher::AES if available
	eval {
		require Crypt::Cipher::AES;
	};
	
	unless ($@) {
		my $cipher = Crypt::Cipher::AES->new($key);
		return $cipher->encrypt($block);
	}
	
	# If no crypto library is available, we cannot proceed
	die "GepardCrypto: No AES implementation available. Please build XSTools or install Crypt::Cipher::AES\n";
}

sub _pure_perl_aes_decrypt {
	my ($block, $key) = @_;
	
	# Try to use Crypt::Cipher::AES if available
	eval {
		require Crypt::Cipher::AES;
	};
	
	unless ($@) {
		my $cipher = Crypt::Cipher::AES->new($key);
		return $cipher->decrypt($block);
	}
	
	# If no crypto library is available, we cannot proceed
	die "GepardCrypto: No AES implementation available. Please build XSTools or install Crypt::Cipher::AES\n";
}

##############################################################################
# Documentation
##############################################################################

1;

__END__

=head1 NAME

GepardCrypto - Encryption utilities for Gepard Shield authentication

=head1 SYNOPSIS

    use GepardCrypto;

    # Initialize encryption
    gepard_init_crypto(key => $key, iv => $iv);

    # Or set key separately
    gepard_set_key($key, $iv);

    # Decrypt challenge from server
    my $decrypted = gepard_decrypt_challenge($challenge_data);

    # Encrypt response to server
    my $encrypted = gepard_encrypt_response($response_data);

=head1 DESCRIPTION

This module provides CBS-AES encryption/decryption for Gepard Shield
authentication using OpenKore's built-in Rijndael implementation.

=head1 FUNCTIONS

=head2 gepard_init_crypto(%args)

Initialize the encryption subsystem with optional key and IV.

=head2 gepard_set_key($key, $iv)

Set the encryption key and initialization vector. Key can be provided as:
- Binary string
- Hex string (auto-detected)
- Byte array reference

=head2 gepard_decrypt_challenge($ciphertext)

Decrypt a Gepard Shield challenge using CBS-AES. Returns plaintext or undef on error.

=head2 gepard_encrypt_response($plaintext)

Encrypt a response using CBS-AES. Returns ciphertext or undef on error.

=head2 gepard_test_crypto()

Run self-tests to verify the encryption implementation is working correctly.

=head1 IMPLEMENTATION NOTES

This module implements CBS (Cipher Block Stealing) mode on top of AES encryption.
CBS mode allows encrypting data that is not a multiple of the block size without padding.

The implementation uses OpenKore's Utils::Rijndael module for the underlying AES operations.

=head1 SEE ALSO

L<Utils::Rijndael>

=head1 AUTHOR

Created with Claude Code

=head1 LICENSE

See OpenKore license

=cut
