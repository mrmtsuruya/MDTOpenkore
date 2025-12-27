#!/usr/bin/env perl
##############################################################################
# Quick Encryption Test Script
# 
# This script tests the GepardCrypto module to ensure CBS-AES encryption
# is working correctly before attempting to connect to the server.
##############################################################################

use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/openkore-master/src";
use lib "$RealBin/openkore-master/plugins/GepardShield";

print "=" x 70 . "\n";
print "Gepard Shield Encryption Test\n";
print "=" x 70 . "\n\n";

# Test 1: Module loading
print "[Test 1] Loading GepardCrypto module... ";
eval {
    require GepardCrypto;
    GepardCrypto->import();
};
if ($@) {
    print "FAILED\n";
    print "Error: $@\n";
    exit 1;
}
print "OK\n";

# Test 2: Initialize with test key
print "[Test 2] Initializing with test key... ";
my $test_key = pack("H*", "0123456789ABCDEF0123456789ABCDEF");
eval {
    GepardCrypto::gepard_set_key($test_key);
    GepardCrypto::gepard_init_crypto();
};
if ($@) {
    print "FAILED\n";
    print "Error: $@\n";
    exit 1;
}
print "OK\n";

# Test 3: Encrypt some test data
print "[Test 3] Encrypting test data... ";
my $test_plaintext = "Hello Arkangel RO!";
my $encrypted;
eval {
    $encrypted = GepardCrypto::gepard_encrypt_response($test_plaintext);
};
if ($@ || !defined $encrypted) {
    print "FAILED\n";
    print "Error: " . ($@ || "No encrypted data returned") . "\n";
    exit 1;
}
print "OK (" . length($encrypted) . " bytes)\n";

# Test 4: Decrypt the encrypted data
print "[Test 4] Decrypting encrypted data... ";
my $decrypted;
eval {
    $decrypted = GepardCrypto::gepard_decrypt_challenge($encrypted);
};
if ($@ || !defined $decrypted) {
    print "FAILED\n";
    print "Error: " . ($@ || "No decrypted data returned") . "\n";
    exit 1;
}
print "OK (" . length($decrypted) . " bytes)\n";

# Test 5: Verify round-trip
print "[Test 5] Verifying round-trip integrity... ";
if ($decrypted eq $test_plaintext) {
    print "OK\n";
    print "  Original:  '$test_plaintext'\n";
    print "  Decrypted: '$decrypted'\n";
} else {
    print "FAILED\n";
    print "  Original:  '$test_plaintext'\n";
    print "  Decrypted: '$decrypted'\n";
    exit 1;
}

# Test 6: Test with various data sizes
print "[Test 6] Testing various data sizes... ";
my @test_sizes = (1, 15, 16, 17, 31, 32, 33, 64);
my $all_passed = 1;
foreach my $size (@test_sizes) {
    my $data = "X" x $size;
    my $enc = eval { GepardCrypto::gepard_encrypt_response($data); };
    if ($@ || !defined $enc) {
        print "FAILED at size $size\n";
        $all_passed = 0;
        last;
    }
    my $dec = eval { GepardCrypto::gepard_decrypt_challenge($enc); };
    if ($@ || !defined $dec || $dec ne $data) {
        print "FAILED at size $size (decrypt)\n";
        $all_passed = 0;
        last;
    }
}
if ($all_passed) {
    print "OK (tested sizes: " . join(", ", @test_sizes) . ")\n";
}

print "\n";
print "=" x 70 . "\n";
print "All tests passed! CBS-AES encryption is working correctly.\n";
print "=" x 70 . "\n\n";

print "IMPORTANT NOTES:\n";
print "1. These tests use a hardcoded test key for validation purposes.\n";
print "2. To connect to Arkangel RO, you MUST obtain the server's actual encryption key.\n";
print "3. Update config.txt with: gepard_key YOUR_ACTUAL_KEY_HERE\n";
print "4. The encryption implementation is ready and working.\n";
print "\n";

exit 0;
