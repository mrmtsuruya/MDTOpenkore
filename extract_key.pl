#!/usr/bin/env perl
##############################################################################
# Gepard DLL Key Extractor
#
# This script attempts to extract the encryption key from gepard.dll
# It looks for common patterns and AES key signatures in the DLL file.
##############################################################################

use strict;
use warnings;
use FindBin qw($RealBin);

print "=" x 70 . "\n";
print "Gepard DLL Key Extractor\n";
print "=" x 70 . "\n\n";

# Check if gepard.dll exists
my @dll_locations = (
    "$RealBin/gepard.dll",
    "$RealBin/ArkangelSEA/gepard.dll",
    "$RealBin/openkore-master/gepard.dll",
);

my $dll_path;
foreach my $path (@dll_locations) {
    if (-f $path) {
        $dll_path = $path;
        last;
    }
}

unless ($dll_path) {
    print "ERROR: gepard.dll not found!\n\n";
    print "Please place gepard.dll in one of these locations:\n";
    foreach my $path (@dll_locations) {
        print "  - $path\n";
    }
    print "\nYou can extract it from the Arkangel RO client:\n";
    print "  https://arkangelrosea.com/\n\n";
    exit 1;
}

print "Found gepard.dll: $dll_path\n";
print "File size: " . (-s $dll_path) . " bytes\n\n";

# Read the DLL file
open my $fh, '<:raw', $dll_path or die "Cannot open $dll_path: $!\n";
my $dll_content;
{
    local $/;
    $dll_content = <$fh>;
}
close $fh;

print "Analyzing DLL for encryption keys...\n\n";

# Method 1: Look for 16, 24, or 32 byte sequences that look like keys
# (high entropy, not all zeros or all 0xFF)
print "[Method 1] Searching for potential AES keys (16/24/32 bytes)...\n";

my @potential_keys;
for my $key_len (16, 24, 32) {
    for (my $i = 0; $i < length($dll_content) - $key_len; $i++) {
        my $candidate = substr($dll_content, $i, $key_len);
        
        # Check if it looks like a key (some entropy, not all same bytes)
        my %byte_counts;
        for my $byte (split //, $candidate) {
            $byte_counts{ord($byte)}++;
        }
        
        # If it has at least 8 different byte values, it might be a key
        if (keys %byte_counts >= 8) {
            # Check if it's not a common pattern
            next if $candidate =~ /^\x00+$/;  # All zeros
            next if $candidate =~ /^\xFF+$/;  # All 0xFF
            next if $candidate =~ /^[\x20-\x7E]+$/;  # All printable ASCII
            
            push @potential_keys, {
                offset => $i,
                length => $key_len,
                data => $candidate,
                hex => unpack("H*", $candidate),
                entropy => keys %byte_counts,
            };
        }
    }
}

# Sort by entropy (higher is better) and take top candidates
@potential_keys = sort { $b->{entropy} <=> $a->{entropy} } @potential_keys;

if (@potential_keys > 0) {
    print "Found " . scalar(@potential_keys) . " potential key candidates\n";
    print "Top 10 candidates (by entropy):\n\n";
    
    for my $i (0 .. 9) {
        last if $i >= @potential_keys;
        my $key = $potential_keys[$i];
        
        print sprintf("  [%d] Offset: 0x%08X, Length: %d bytes, Entropy: %d/256\n",
            $i + 1, $key->{offset}, $key->{length}, $key->{entropy});
        print "      Hex: $key->{hex}\n";
        
        # Try to show some context
        my $context_start = $key->{offset} - 16;
        $context_start = 0 if $context_start < 0;
        my $context = substr($dll_content, $context_start, 64);
        my $context_hex = unpack("H*", $context);
        print "      Context: " . substr($context_hex, 0, 80) . "...\n\n";
    }
} else {
    print "No obvious key candidates found using entropy analysis.\n\n";
}

# Method 2: Look for common AES key expansion patterns
print "[Method 2] Searching for AES key schedule patterns...\n";

# AES key schedule has specific patterns - look for repeating structures
# This is more advanced and would require deeper analysis

print "Note: This requires manual analysis of the DLL structure.\n\n";

# Method 3: Look for strings that might be keys
print "[Method 3] Searching for hex-encoded key strings...\n";

# Look for patterns like "0123456789ABCDEF..." in the DLL
while ($dll_content =~ /([0-9A-Fa-f]{32,64})/g) {
    my $hex_string = $1;
    if (length($hex_string) == 32 || length($hex_string) == 48 || length($hex_string) == 64) {
        print "  Found hex string (length " . length($hex_string) . "): $hex_string\n";
    }
}

print "\n";
print "=" x 70 . "\n";
print "RECOMMENDATIONS\n";
print "=" x 70 . "\n\n";

print "1. Manual Analysis:\n";
print "   - Use a debugger (x64dbg, IDA Pro, Ghidra) to debug gepard.dll\n";
print "   - Set breakpoints on AES functions (AES_encrypt, rijndael_*, etc.)\n";
print "   - Run the Arkangel RO client and capture the key during authentication\n\n";

print "2. Memory Dump:\n";
print "   - Attach a debugger to the RO client process during authentication\n";
print "   - Dump memory and search for the key being used\n";
print "   - Look for data passed to AES encryption functions\n\n";

print "3. Network Analysis:\n";
print "   - Capture packets with Wireshark during successful authentication\n";
print "   - Analyze challenge/response patterns\n";
print "   - Try to brute force or analyze the encryption scheme\n\n";

print "4. Use the top key candidates above:\n";
print "   - Try each candidate in OpenKore's config.txt\n";
print "   - Set: gepard_key CANDIDATE_HEX_HERE\n";
print "   - Test connection and check if authentication succeeds\n\n";

if (@potential_keys > 0) {
    print "QUICK TEST: Try these keys first:\n\n";
    for my $i (0 .. 2) {
        last if $i >= @potential_keys;
        print "  gepard_key " . $potential_keys[$i]->{hex} . "\n";
    }
    print "\n";
}

print "For more information, see:\n";
print "  - QUICKSTART.md (setup guide)\n";
print "  - PROJECT_COMPLETE.md (implementation status)\n\n";

exit 0;
