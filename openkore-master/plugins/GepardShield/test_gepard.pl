#!/usr/bin/env perl
##############################################################################
#  Gepard Shield Testing Script
#
#  This script tests the GepardCrypto module and helps validate your
#  CBS-AES implementation.
#
#  Usage:
#    perl test_gepard.pl
#    perl test_gepard.pl --key YOUR_HEX_KEY --challenge CHALLENGE_HEX
#
##############################################################################

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin";
use lib "$RealBin/../../src";
use Getopt::Long;

# Try to load the crypto module
eval {
	require GepardCrypto;
	GepardCrypto->import();
};

if ($@) {
	die "Failed to load GepardCrypto module: $@\n";
}

##############################################################################
# Configuration
##############################################################################

my $opt_key;
my $opt_iv;
my $opt_challenge;
my $opt_response;
my $opt_verbose;
my $opt_test_only;

GetOptions(
	'key=s' => \$opt_key,
	'iv=s' => \$opt_iv,
	'challenge=s' => \$opt_challenge,
	'response=s' => \$opt_response,
	'verbose' => \$opt_verbose,
	'test' => \$opt_test_only,
	'help' => \&show_help,
) or die "Invalid options. Use --help for usage information.\n";

##############################################################################
# Main Program
##############################################################################

print "=" x 70 . "\n";
print "Gepard Shield Encryption Test Utility\n";
print "=" x 70 . "\n\n";

if ($opt_test_only) {
	run_self_test();
	exit 0;
}

# Test with provided challenge data
if ($opt_challenge) {
	test_challenge_decryption($opt_challenge, $opt_key, $opt_iv);
	exit 0;
}

# Test with provided response data
if ($opt_response) {
	test_response_encryption($opt_response, $opt_key, $opt_iv);
	exit 0;
}

# Run comprehensive tests
run_comprehensive_tests();

##############################################################################
# Test Functions
##############################################################################

sub run_self_test {
	print "Running GepardCrypto self-test...\n\n";
	GepardCrypto::gepard_test_crypto();
	print "\nSelf-test complete.\n";
}

sub test_challenge_decryption {
	my ($challenge_hex, $key_hex, $iv_hex) = @_;

	print "Testing Challenge Decryption\n";
	print "-" x 70 . "\n\n";

	# Convert hex to binary
	my $challenge = pack("H*", $challenge_hex);
	print "Challenge (hex):  $challenge_hex\n";
	print "Challenge length: " . length($challenge) . " bytes\n\n";

	# Set up encryption
	if ($key_hex) {
		print "Using provided key: $key_hex\n";
		gepard_set_key($key_hex, $iv_hex);
	} else {
		print "WARNING: No key provided, using default test key\n";
		gepard_set_key("0" x 64);  # 32-byte zero key
	}

	gepard_init_crypto();

	# Attempt decryption
	print "\nAttempting decryption...\n";
	my $decrypted = gepard_decrypt_challenge($challenge);

	if ($decrypted) {
		print "SUCCESS! Decrypted challenge:\n";
		print "  Hex:   " . unpack("H*", $decrypted) . "\n";
		print "  ASCII: " . format_ascii($decrypted) . "\n";
		print "  Bytes: " . format_bytes($decrypted) . "\n";
	} else {
		print "FAILED: Could not decrypt challenge\n";
		print "  This is expected if CBS-AES is not yet implemented.\n";
	}
}

sub test_response_encryption {
	my ($response_data, $key_hex, $iv_hex) = @_;

	print "Testing Response Encryption\n";
	print "-" x 70 . "\n\n";

	# Set up encryption
	if ($key_hex) {
		gepard_set_key($key_hex, $iv_hex);
	} else {
		print "WARNING: No key provided, using default test key\n";
		gepard_set_key("0" x 64);
	}

	gepard_init_crypto();

	# Create test response
	my $response;
	if ($response_data =~ /^[0-9a-fA-F]+$/) {
		# Hex input
		$response = pack("H*", $response_data);
		print "Response (hex):   $response_data\n";
	} else {
		# ASCII input
		$response = $response_data;
		print "Response (ASCII): $response_data\n";
	}

	print "Response length:  " . length($response) . " bytes\n\n";

	# Attempt encryption
	print "Attempting encryption...\n";
	my $encrypted = gepard_encrypt_response($response);

	if ($encrypted) {
		print "SUCCESS! Encrypted response:\n";
		print "  Hex:   " . unpack("H*", $encrypted) . "\n";
		print "  Bytes: " . length($encrypted) . "\n";
	} else {
		print "FAILED: Could not encrypt response\n";
		print "  This is expected if CBS-AES is not yet implemented.\n";
	}
}

sub run_comprehensive_tests {
	print "Running Comprehensive Tests\n";
	print "-" x 70 . "\n\n";

	# Test 1: Module loading
	print "[1/5] Testing module loading... ";
	if (defined &gepard_init_crypto) {
		print "PASS\n";
	} else {
		print "FAIL\n";
		die "Could not load GepardCrypto functions\n";
	}

	# Test 2: Initialization
	print "[2/5] Testing initialization... ";
	eval {
		gepard_set_key("0123456789ABCDEF0123456789ABCDEF");
		gepard_init_crypto();
	};
	if ($@) {
		print "FAIL\n";
		die "Initialization failed: $@\n";
	}
	print "PASS\n";

	# Test 3: Example challenge from logs
	print "[3/5] Testing with real challenge data... \n";
	my $real_challenge = "F77FFBCE835979AF393A5BCBE2BAF779B58F8F548B5A362ED5A3EA00C04647E7";
	test_challenge_decryption($real_challenge);

	# Test 4: Round-trip test
	print "\n[4/5] Testing encryption round-trip... \n";
	my $test_data = "Test data 123";
	print "  Original: $test_data\n";

	my $encrypted = gepard_encrypt_response($test_data);
	if ($encrypted) {
		print "  Encrypted: " . unpack("H*", $encrypted) . "\n";

		my $decrypted = gepard_decrypt_challenge($encrypted);
		if ($decrypted && $decrypted eq $test_data) {
			print "  Round-trip: PASS\n";
		} else {
			print "  Round-trip: FAIL (decrypted doesn't match original)\n";
		}
	} else {
		print "  Encryption failed (expected until implemented)\n";
	}

	# Test 5: Key validation
	print "\n[5/5] Testing key validation... \n";
	foreach my $key_len (16, 24, 32, 15, 33) {
		my $test_key = "0" x ($key_len * 2);  # Hex string
		gepard_set_key($test_key);
		my ($key) = gepard_get_key();

		if (length($key) == $key_len) {
			my $expected = ($key_len == 16 || $key_len == 24 || $key_len == 32) ? "VALID" : "INVALID";
			print "  ${key_len}-byte key: $expected\n";
		}
	}

	print "\n" . "=" x 70 . "\n";
	print "Comprehensive tests complete.\n";
	print "\nNOTE: Some tests will fail until CBS-AES is implemented.\n";
	print "See GEPARD_SHIELD_README.md for implementation guide.\n";
}

##############################################################################
# Utility Functions
##############################################################################

sub format_ascii {
	my ($data) = @_;
	my $ascii = $data;
	$ascii =~ s/[^[:print:]]/./g;
	return $ascii;
}

sub format_bytes {
	my ($data) = @_;
	my @bytes = unpack("C*", $data);
	return join(" ", map { sprintf("%02X", $_) } @bytes);
}

sub show_help {
	print <<'HELP';
Gepard Shield Testing Script

Usage:
  perl test_gepard.pl [options]

Options:
  --test                Run self-test only
  --key HEX             Encryption key (hex string)
  --iv HEX              Initialization vector (hex string)
  --challenge HEX       Test challenge decryption with hex data
  --response DATA       Test response encryption with data
  --verbose             Enable verbose output
  --help                Show this help message

Examples:

  # Run self-test
  perl test_gepard.pl --test

  # Test with real challenge from server
  perl test_gepard.pl --challenge F77FFBCE835979AF393A5BCBE2BAF779...

  # Test with specific key
  perl test_gepard.pl --key 0123456789ABCDEF... --challenge F77F...

  # Test response encryption
  perl test_gepard.pl --response "Test response data"

  # Run comprehensive tests
  perl test_gepard.pl

HELP
	exit 0;
}

##############################################################################
# Entry Point
##############################################################################

# If no specific test was run, show help
if (!$opt_test_only && !$opt_challenge && !$opt_response) {
	# Default: run comprehensive tests
	# (already handled above)
}

print "\nDone.\n";

exit 0;
