#!/usr/bin/env perl
##############################################################################
# Find Gepard Files
#
# This script searches for gepard.dll and related files in the directory tree
##############################################################################

use strict;
use warnings;
use File::Find;
use FindBin qw($RealBin);

print "=" x 70 . "\n";
print "Searching for Gepard Shield files...\n";
print "=" x 70 . "\n\n";

my @found_files;
my %file_types = (
    'gepard.dll' => 'Gepard Shield DLL (contains encryption key)',
    'gepard.grf' => 'Gepard Shield GRF file',
    'Ragexe.exe' => 'Ragnarok executable',
    'RagexeRE.exe' => 'Ragnarok RE executable',
);

print "Searching directory: $RealBin\n";
print "This may take a moment...\n\n";

find(sub {
    my $file = $File::Find::name;
    my $basename = $_;
    
    # Check if it's one of the files we're looking for
    foreach my $target_file (keys %file_types) {
        if (lc($basename) eq lc($target_file)) {
            my $size = -s $file;
            push @found_files, {
                name => $basename,
                path => $file,
                size => $size,
                description => $file_types{$target_file},
            };
        }
    }
    
    # Also look for any .dll files with "gepard" in the name
    if ($basename =~ /gepard/i && $basename =~ /\.dll$/i) {
        my $size = -s $file;
        push @found_files, {
            name => $basename,
            path => $file,
            size => $size,
            description => 'Gepard-related DLL',
        } unless grep { $_->{path} eq $file } @found_files;
    }
}, $RealBin);

print "=" x 70 . "\n";
print "SEARCH RESULTS\n";
print "=" x 70 . "\n\n";

if (@found_files) {
    print "Found " . scalar(@found_files) . " file(s):\n\n";
    
    foreach my $file (@found_files) {
        print "  File: $file->{name}\n";
        print "  Path: $file->{path}\n";
        print "  Size: " . format_size($file->{size}) . "\n";
        print "  Info: $file->{description}\n";
        
        # Check if it's usable
        if ($file->{size} == 0) {
            print "  Status: ⚠️  EMPTY FILE (0 bytes)\n";
        } elsif ($file->{size} < 1000) {
            print "  Status: ⚠️  VERY SMALL (may be corrupted)\n";
        } else {
            print "  Status: ✅ FOUND (ready to analyze)\n";
            
            if ($file->{name} =~ /gepard\.dll/i) {
                print "\n  ⭐ Ready to extract key! Run:\n";
                print "     perl extract_key.pl\n";
            }
        }
        print "\n";
    }
} else {
    print "❌ No Gepard Shield files found.\n\n";
    print "Expected files:\n";
    foreach my $file (sort keys %file_types) {
        print "  - $file: $file_types{$file}\n";
    }
    print "\n";
    print "Please ensure the Arkangel RO client is extracted in this directory.\n";
    print "The client should contain these files in its installation folder.\n\n";
}

print "=" x 70 . "\n";
print "NEXT STEPS\n";
print "=" x 70 . "\n\n";

if (grep { $_->{name} =~ /gepard\.dll/i && $_->{size} > 1000 } @found_files) {
    print "✅ gepard.dll found! You can now:\n\n";
    print "1. Extract the encryption key:\n";
    print "   perl extract_key.pl\n\n";
    print "2. Configure the key in config.txt\n\n";
    print "3. Test the connection:\n";
    print "   cd openkore-master && perl openkore.pl\n\n";
} else {
    print "📥 Waiting for client files:\n\n";
    print "Option 1: Extract the full client\n";
    print "  - Download ArkangelSEA Official.rar\n";
    print "  - Extract to this directory\n";
    print "  - Run this script again\n\n";
    
    print "Option 2: Upload just gepard.dll\n";
    print "  - Find gepard.dll in the RO client\n";
    print "  - Copy it to this directory\n";
    print "  - Run: perl extract_key.pl\n\n";
    
    print "Option 3: Provide the key directly\n";
    print "  - If you already have the encryption key\n";
    print "  - Add to config.txt: gepard_key YOUR_KEY\n";
    print "  - Run: perl check_config.pl\n\n";
}

print "For more help, see:\n";
print "  - START_HERE.md\n";
print "  - KEY_EXTRACTION_GUIDE.md\n\n";

sub format_size {
    my $size = shift;
    return "0 bytes" if $size == 0;
    return "$size bytes" if $size < 1024;
    return sprintf("%.2f KB", $size / 1024) if $size < 1024 * 1024;
    return sprintf("%.2f MB", $size / (1024 * 1024));
}

exit 0;
