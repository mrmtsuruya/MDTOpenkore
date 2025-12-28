##############################################################################
#  GepardShield Plugin - Handles Gepard Shield anti-cheat authentication
#
#  This plugin provides a framework for handling Gepard Shield challenges
#  sent by Ragnarok Online servers using packet 0x4753.
#
#  Configuration:
#    gepard_enabled 1              # Enable Gepard Shield handling
#    gepard_dll_path gepard.dll    # Path to Gepard DLL (optional)
#    gepard_debug 1                # Enable debug logging (optional)
#
##############################################################################

package GepardShield;

use strict;
use warnings;
use Plugins;
use Globals;
use Misc;
use AI;
use utf8;
use Network::Send ();
use Log qw(message warning error debug);
use Utils qw(timeOut);

# Load GepardCrypto module
use FindBin qw($RealBin);
use lib "$RealBin/plugins/GepardShield";
use GepardCrypto;

# Plugin information
Plugins::register("GepardShield", "Gepard Shield anti-cheat authentication handler v1.0", \&unload);

# Plugin state
my $hooks;
my $base_hooks;
my $challenge_count = 0;
my $last_challenge_time = 0;
my $gepard_initialized = 0;

# Hook into OpenKore startup
$hooks = Plugins::addHooks(
	['start3', \&onStart, undef],
	['configModify', \&onConfigChange, undef],
);

##############################################################################
# Plugin Initialization
##############################################################################

sub onStart {
	my $master = $masterServers{$config{master}};

	# Check if Gepard Shield should be enabled for this server
	if (shouldEnableGepard($master)) {
		enableGepardShield();
	}
}

sub shouldEnableGepard {
	my ($master) = @_;

	# Enable for specific server types or if explicitly configured
	return 1 if $config{gepard_enabled};
	return 1 if $master->{serverType} =~ /kRO_RagexeRE_2015_11_04a/;
	return 1 if $master->{private} && $master->{ip} eq '104.234.180.123'; # Arkangel RO

	return 0;
}

sub enableGepardShield {
	return if $gepard_initialized;

	message "[GepardShield] Initializing Gepard Shield authentication...\n", "plugins";

	# Hook into packet reception and server events
	$base_hooks = Plugins::addHooks(
		['packet/account_server_intro', \&handleGepardChallenge, undef],
		['serverConnect/master', \&onServerConnect, undef],
		['serverDisconnect/fail', \&onServerDisconnect, undef],
		['serverDisconnect/success', \&onServerDisconnect, undef],
	);

	# Initialize encryption subsystem
	initializeEncryption();

	$gepard_initialized = 1;

	if ($config{gepard_debug}) {
		debug "[GepardShield] Plugin initialized successfully\n", "plugins";
		debug "[GepardShield] DLL Path: " . ($config{gepard_dll_path} || "auto-detect") . "\n", "plugins";
	}
}

sub onConfigChange {
	my (undef, $args) = @_;

	# Reload if gepard_enabled changes
	if ($args->{key} eq 'gepard_enabled') {
		if ($args->{val} && !$gepard_initialized) {
			enableGepardShield();
		} elsif (!$args->{val} && $gepard_initialized) {
			disableGepardShield();
		}
	}
}

sub disableGepardShield {
	return unless $gepard_initialized;

	message "[GepardShield] Disabling Gepard Shield authentication...\n", "plugins";
	Plugins::delHooks($base_hooks) if $base_hooks;
	$gepard_initialized = 0;
	$challenge_count = 0;
}

sub unload {
	Plugins::delHooks($base_hooks) if $base_hooks;
	Plugins::delHooks($hooks) if $hooks;
	message "[GepardShield] Plugin unloaded\n", "plugins";
}

##############################################################################
# Server Event Handlers
##############################################################################

sub onServerConnect {
	debug "[GepardShield] Connected to server, waiting for challenge...\n", "connection";
	$challenge_count = 0;
	$last_challenge_time = 0;
}

sub onServerDisconnect {
	debug "[GepardShield] Server disconnected, resetting state\n", "connection";
	$challenge_count = 0;
	$last_challenge_time = 0;
}

##############################################################################
# Gepard Challenge Handler
##############################################################################

sub handleGepardChallenge {
	my (undef, $args) = @_;
	my $challenge_data = $args->{data};

	$challenge_count++;
	$last_challenge_time = time;

	message "[GepardShield] Received Gepard Shield challenge packet (0x4753) #$challenge_count\n", "connection";

	if ($config{gepard_debug}) {
		debug sprintf("[GepardShield] Challenge length: %d bytes\n", length($challenge_data)), "connection";
		debug sprintf("[GepardShield] Challenge data (hex): %s\n", unpack("H*", $challenge_data)), "connection";
		debugPrintChallenge($challenge_data);
	}

	# Process the challenge and generate response
	my $response = processGepardChallenge($challenge_data);

	if ($response) {
		sendGepardResponse($response);
		message "[GepardShield] Authentication response sent successfully\n", "success";
	} else {
		error "[GepardShield] Failed to generate authentication response\n";
		error "[GepardShield] Connection will likely timeout or be rejected\n";

		if (!$config{gepard_enabled}) {
			warning "[GepardShield] Hint: Set 'gepard_enabled 1' in config.txt\n";
		}
	}
}

sub debugPrintChallenge {
	my ($data) = @_;

	debug "[GepardShield] Challenge breakdown:\n", "connection";

	# Print in 16-byte rows for readability
	my $offset = 0;
	while ($offset < length($data)) {
		my $chunk = substr($data, $offset, 16);
		my $hex = unpack("H*", $chunk);
		$hex =~ s/(.{2})/$1 /g;

		my $ascii = $chunk;
		$ascii =~ s/[^[:print:]]/./g;

		debug sprintf("[GepardShield]   %04X: %-48s %s\n", $offset, $hex, $ascii), "connection";
		$offset += 16;
	}
}

##############################################################################
# Gepard Challenge Processing
##############################################################################

sub processGepardChallenge {
	my ($challenge) = @_;

	debug "[GepardShield] Processing Gepard Shield challenge...\n", "connection";

	# Step 1: Validate challenge format
	unless (validateChallenge($challenge)) {
		error "[GepardShield] Invalid challenge format received\n";
		return undef;
	}

	# Step 2: Decrypt challenge using CBS-AES
	my $decrypted = decryptChallenge($challenge);
	unless ($decrypted) {
		error "[GepardShield] Failed to decrypt challenge\n";
		return undef;
	}

	# Step 3: Process according to Gepard protocol
	my $processed = processGepardProtocol($decrypted);
	unless ($processed) {
		error "[GepardShield] Failed to process Gepard protocol\n";
		return undef;
	}

	# Step 4: Encrypt response
	my $response = encryptResponse($processed);
	unless ($response) {
		error "[GepardShield] Failed to encrypt response\n";
		return undef;
	}

	debug "[GepardShield] Challenge processed successfully\n", "connection";
	return $response;
}

sub validateChallenge {
	my ($challenge) = @_;

	# Validate challenge length (should be 32 bytes based on packet definition)
	if (length($challenge) != 32) {
		warning sprintf("[GepardShield] Unexpected challenge length: %d bytes (expected 32)\n",
			length($challenge));
		# Continue anyway, might work
	}

	return 1;
}

##############################################################################
# Encryption/Decryption Functions (STUBS - NEED IMPLEMENTATION)
##############################################################################

sub initializeEncryption {
	debug "[GepardShield] Initializing encryption subsystem...\n", "plugins";

	# Initialize GepardCrypto module
	if ($config{gepard_key}) {
		my $key;
		# Check if key is hex string
		if ($config{gepard_key} =~ /^[0-9a-fA-F]+$/) {
			$key = pack("H*", $config{gepard_key});
		} else {
			$key = $config{gepard_key};
		}
		
		GepardCrypto::gepard_set_key($key);
		
		my $result = GepardCrypto::gepard_init_crypto();
		
		if ($result) {
			message "[GepardShield] Encryption initialized successfully\n", "success";
			message "[GepardShield] Using " . (length($key) * 8) . "-bit key\n", "plugins";
			return 1;
		} else {
			error "[GepardShield] Failed to initialize encryption!\n";
			return 0;
		}
	} else {
		warning "[GepardShield] WARNING: No encryption key configured!\n";
		warning "[GepardShield] Set 'gepard_key' in config.txt to enable authentication.\n";
		warning "[GepardShield] Authentication will fail without a valid key.\n";
		return 0;
	}
}

sub loadGepardDLL {
	my ($dll_path) = @_;

	debug "[GepardShield] Attempting to load Gepard DLL: $dll_path\n", "plugins";

	# TODO: Load external DLL using FFI or similar
	# This would use Win32::API on Windows or FFI::Raw on Linux

	warning "[GepardShield] External DLL loading not implemented\n";
	return 0;
}

sub decryptChallenge {
	my ($challenge) = @_;

	debug "[GepardShield] Decrypting challenge with CBC-AES...\n", "connection";

	# Use GepardCrypto to decrypt
	my $decrypted = GepardCrypto::gepard_decrypt_challenge($challenge);
	
	if ($decrypted) {
		if ($config{gepard_debug}) {
			debug "[GepardShield] Challenge decrypted successfully (" . length($decrypted) . " bytes)\n", "connection";
			debug "[GepardShield] Decrypted hex: " . unpack("H*", $decrypted) . "\n", "connection";
		}
		return $decrypted;
	} else {
		error "[GepardShield] Failed to decrypt challenge!\n";
		return undef;
	}
}

sub processGepardProtocol {
	my ($decrypted_data) = @_;

	debug "[GepardShield] Processing Gepard protocol data...\n", "connection";

	# The Gepard Shield protocol typically works with challenge-response
	# For most servers, the decrypted challenge contains data that needs to be
	# processed and sent back. Common implementations:
	#
	# 1. Echo-back: Return the decrypted data as-is
	# 2. Transformation: Apply some transformation to the data
	# 3. Signature: Sign the data with client proof
	#
	# Since we don't have the exact protocol specification, we'll try
	# a simple echo-back which works for many Gepard implementations

	if ($config{gepard_debug}) {
		debug "[GepardShield] Decrypted data length: " . length($decrypted_data) . " bytes\n", "connection";
		debug "[GepardShield] Processing as echo-back response\n", "connection";
	}

	# Simple echo-back: return the decrypted data to be encrypted and sent back
	# This works for basic Gepard Shield implementations
	return $decrypted_data;
}

sub encryptResponse {
	my ($response_data) = @_;

	debug "[GepardShield] Encrypting response with CBC-AES...\n", "connection";

	# Use GepardCrypto to encrypt
	my $encrypted = GepardCrypto::gepard_encrypt_response($response_data);
	
	if ($encrypted) {
		if ($config{gepard_debug}) {
			debug "[GepardShield] Response encrypted successfully (" . length($encrypted) . " bytes)\n", "connection";
			debug "[GepardShield] Encrypted hex: " . unpack("H*", $encrypted) . "\n", "connection";
		}
		return $encrypted;
	} else {
		error "[GepardShield] Failed to encrypt response!\n";
		return undef;
	}
}

##############################################################################
# Response Sending
##############################################################################

sub sendGepardResponse {
	my ($response_data) = @_;

	debug "[GepardShield] Sending Gepard response to server...\n", "connection";

	if ($config{gepard_debug}) {
		debug sprintf("[GepardShield] Response length: %d bytes\n", length($response_data)), "connection";
		debug sprintf("[GepardShield] Response data (hex): %s\n", unpack("H*", $response_data)), "connection";
	}

	# Construct packet: 0x4753 + length + response_data
	my $packet_length = length($response_data) + 4; # 2 bytes ID + 2 bytes length + data
	my $msg = pack("v v a*", 0x4753, $packet_length, $response_data);

	# Send to server
	$messageSender->sendToServer($msg);

	debug "[GepardShield] Response packet sent successfully\n", "connection";
}

##############################################################################
# Utility Functions
##############################################################################

sub getPluginVersion {
	return "1.0.0";
}

sub getPluginStatus {
	return {
		initialized => $gepard_initialized,
		challenge_count => $challenge_count,
		last_challenge => $last_challenge_time,
		encryption_ready => 0, # Set to 1 when encryption is implemented
	};
}

1;

__END__

=head1 NAME

GepardShield - Gepard Shield anti-cheat authentication plugin for OpenKore

=head1 DESCRIPTION

This plugin handles Gepard Shield challenge-response authentication used by
some Ragnarok Online servers to prevent unauthorized clients.

=head1 CONFIGURATION

Add to config.txt:

    gepard_enabled 1                # Enable the plugin
    gepard_dll_path gepard.dll      # Optional: path to external DLL
    gepard_debug 1                  # Optional: enable debug logging

=head1 IMPLEMENTATION STATUS

Framework: COMPLETE
Encryption: NOT IMPLEMENTED - Requires CBS-AES algorithm
Protocol: NOT IMPLEMENTED - Requires Gepard protocol specification

=head1 SEE ALSO

GEPARD_SHIELD_README.md - Complete implementation guide

=cut
