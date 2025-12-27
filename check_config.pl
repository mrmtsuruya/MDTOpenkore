#!/usr/bin/env perl
##############################################################################
# OpenKore Configuration Checker
#
# This script verifies that OpenKore is properly configured for Arkangel RO
# and checks that the Gepard Shield plugin is ready to use.
##############################################################################

use strict;
use warnings;
use FindBin qw($RealBin);

print "=" x 70 . "\n";
print "OpenKore Configuration Checker for Arkangel RO\n";
print "=" x 70 . "\n\n";

my $all_ok = 1;

# Check 1: Config file exists
print "[1/7] Checking config.txt exists... ";
if (-f "$RealBin/openkore-master/control/config.txt") {
    print "✓ OK\n";
} else {
    print "✗ FAILED\n";
    print "      Config file not found!\n";
    $all_ok = 0;
}

# Check 2: GepardShield plugin exists
print "[2/7] Checking GepardShield plugin... ";
if (-f "$RealBin/openkore-master/plugins/GepardShield/GepardShield.pl" &&
    -f "$RealBin/openkore-master/plugins/GepardShield/GepardCrypto.pm") {
    print "✓ OK\n";
} else {
    print "✗ FAILED\n";
    print "      Plugin files not found!\n";
    $all_ok = 0;
}

# Check 3: Read config file
print "[3/7] Reading configuration... ";
my %config;
if (open my $fh, '<', "$RealBin/openkore-master/control/config.txt") {
    while (my $line = <$fh>) {
        next if $line =~ /^\s*#/;  # Skip comments
        next if $line =~ /^\s*$/;  # Skip empty lines
        if ($line =~ /^(\w+)\s+(.+)/) {
            $config{$1} = $2;
            $config{$1} =~ s/\s+$//;  # Trim trailing whitespace
        }
    }
    close $fh;
    print "✓ OK\n";
} else {
    print "✗ FAILED\n";
    print "      Cannot read config file!\n";
    $all_ok = 0;
}

# Check 4: Server configuration
print "[4/7] Checking server selection... ";
if ($config{server} && $config{server} =~ /Arkangel/i) {
    print "✓ OK (server: $config{server})\n";
} else {
    print "⚠ WARNING\n";
    print "      Server not set to 'Arkangel RO'\n";
    print "      Current: " . ($config{server} || "not set") . "\n";
}

# Check 5: Credentials
print "[5/7] Checking credentials... ";
my $creds_ok = 1;
if (!$config{username} || $config{username} =~ /YOUR_USERNAME/) {
    print "\n      ⚠ username not configured\n";
    $creds_ok = 0;
}
if (!$config{password} || $config{password} =~ /YOUR_PASSWORD/) {
    print "      ⚠ password not configured\n";
    $creds_ok = 0;
}
if (!$config{char} || $config{char} =~ /YOUR_CHARACTER/) {
    print "      ⚠ character not configured\n";
    $creds_ok = 0;
}

if ($creds_ok) {
    print "✓ OK\n";
    print "      username: $config{username}\n";
    print "      char: $config{char}\n";
} else {
    print "⚠ INCOMPLETE\n";
    print "      Please set username, password, and char in config.txt\n";
}

# Check 6: Gepard Shield configuration
print "[6/7] Checking Gepard Shield config... ";
my $gepard_ok = 1;

if (!$config{gepard_enabled} || $config{gepard_enabled} ne '1') {
    print "\n      ⚠ gepard_enabled not set to 1\n";
    $gepard_ok = 0;
}

if (!$config{gepard_key} || $config{gepard_key} =~ /YOUR_/) {
    print "      ✗ gepard_key NOT CONFIGURED (CRITICAL!)\n";
    $gepard_ok = 0;
    $all_ok = 0;
} elsif ($config{gepard_key} =~ /^[0-9a-fA-F]{32,64}$/) {
    my $key_len = length($config{gepard_key}) / 2;
    print "✓ OK\n";
    print "      Key configured: $key_len bytes (" . ($key_len * 8) . "-bit)\n";
} else {
    print "      ⚠ gepard_key format may be incorrect\n";
    print "      Expected: hex string (32, 48, or 64 characters)\n";
    print "      Current length: " . length($config{gepard_key}) . " characters\n";
}

if ($config{gepard_debug} && $config{gepard_debug} eq '1') {
    print "      Debug mode: enabled\n";
}

# Check 7: Test encryption module
print "[7/7] Testing encryption module... ";
my $test_result = `perl $RealBin/test_encryption.pl 2>&1`;
if ($test_result =~ /All tests passed/) {
    print "✓ OK\n";
    print "      Encryption is working correctly\n";
} else {
    print "⚠ WARNING\n";
    print "      Encryption test had issues\n";
    print "      Run: perl test_encryption.pl for details\n";
}

# Summary
print "\n";
print "=" x 70 . "\n";
print "SUMMARY\n";
print "=" x 70 . "\n";

if ($all_ok && $creds_ok && $gepard_ok) {
    print "✅ ALL CHECKS PASSED!\n\n";
    print "Your OpenKore is properly configured for Arkangel RO.\n";
    print "You can now run: cd openkore-master && perl openkore.pl\n";
} elsif ($all_ok && !$gepard_ok) {
    print "⚠️ ENCRYPTION KEY REQUIRED\n\n";
    print "Everything else is configured correctly, but you need the Gepard\n";
    print "encryption key. Set 'gepard_key' in config.txt with the actual\n";
    print "key from Arkangel RO server.\n\n";
    print "Once you have the key, OpenKore will be ready to connect.\n";
} elsif ($all_ok && !$creds_ok) {
    print "⚠️ CREDENTIALS NEEDED\n\n";
    print "Set your username, password, and character name in config.txt\n";
} else {
    print "❌ CONFIGURATION ISSUES\n\n";
    print "Please fix the errors above before attempting to connect.\n";
}

print "\n";
print "For more information, see:\n";
print "  - QUICKSTART.md (setup guide)\n";
print "  - PROJECT_COMPLETE.md (implementation status)\n";
print "  - GEPARD_SHIELD_README.md (technical documentation)\n";
print "\n";

exit($all_ok ? 0 : 1);
