#!/usr/bin/env perl
##############################################################################
# Automatic Gepard Key Tester
# Tests multiple encryption keys automatically until one works
##############################################################################

use strict;
use warnings;
use File::Copy;

# Backup key candidates from entropy analysis (ranked by entropy score)
my @key_candidates = (
    'd150f7d25803840452acdc9423ca66c1',  # Key #1 (current - highest entropy)
    '50f7d25803840452acdc9423ca66c1a4',  # Key #2
    '6a878404d2823ba4c16c2400da894c25',  # Key #3
    'c6044c3e0fbe140cc0cae533c366f7d9',  # Key #4
    '044c3e0fbe140cc0cae533c366f7d9e8',  # Key #5
    '44c3e0fbe140cc0cae533c366f7d9e89',  # Key #6
    '4c3e0fbe140cc0cae533c366f7d9e89e',  # Key #7
    'c3e0fbe140cc0cae533c366f7d9e89e4',  # Key #8
    '3e0fbe140cc0cae533c366f7d9e89e49',  # Key #9
    'e0fbe140cc0cae533c366f7d9e89e490',  # Key #10
    '0fbe140cc0cae533c366f7d9e89e4905',  # Key #11
    'fbe140cc0cae533c366f7d9e89e49057',  # Key #12
    'be140cc0cae533c366f7d9e89e490570',  # Key #13
    'e140cc0cae533c366f7d9e89e4905701',  # Key #14
    '140cc0cae533c366f7d9e89e49057015',  # Key #15
    '40cc0cae533c366f7d9e89e490570150',  # Key #16
    '0cc0cae533c366f7d9e89e490570150f',  # Key #17
    'cc0cae533c366f7d9e89e490570150f7',  # Key #18
    'c0cae533c366f7d9e89e490570150f7d',  # Key #19
    '0cae533c366f7d9e89e490570150f7d2',  # Key #20
);

my $config_file = 'openkore-master/control/config.txt';
my $backup_file = "$config_file.backup";

print "\n";
print "="x70 . "\n";
print "Automatic Gepard Shield Key Tester\n";
print "="x70 . "\n";
print "\n";
print "This script will test multiple encryption keys automatically.\n";
print "Total keys to test: " . scalar(@key_candidates) . "\n";
print "\n";

# Check if config file exists
unless (-f $config_file) {
    die "ERROR: Config file not found: $config_file\n";
}

# Create backup if it doesn't exist
unless (-f $backup_file) {
    copy($config_file, $backup_file) or die "Failed to create backup: $!\n";
    print "✓ Created backup: $backup_file\n\n";
}

# Read current config
open(my $fh, '<', $config_file) or die "Cannot read config: $!\n";
my @config_lines = <$fh>;
close($fh);

print "Testing keys in order (highest entropy first):\n";
print "-" x 70 . "\n";

my $test_num = 0;
foreach my $key (@key_candidates) {
    $test_num++;
    
    print "\n[$test_num/" . scalar(@key_candidates) . "] Testing key: $key\n";
    
    # Update config with new key
    my @new_config = @config_lines;
    for (my $i = 0; $i < @new_config; $i++) {
        if ($new_config[$i] =~ /^gepard_key\s+/) {
            $new_config[$i] = "gepard_key $key\n";
            last;
        }
    }
    
    # Write updated config
    open(my $out, '>', $config_file) or die "Cannot write config: $!\n";
    print $out @new_config;
    close($out);
    
    print "    Config updated with key #$test_num\n";
    print "    Now run: cd openkore-master && perl openkore.pl\n";
    print "    If authentication succeeds, key is correct!\n";
    print "    If it times out, press Ctrl+C and this script will try next key.\n";
    print "\n";
    print "Press Enter to continue with this key, or Ctrl+C to skip to next...";
    
    my $input = <STDIN>;
    
    # If user pressed Enter, they want to test this key
    print "Starting OpenKore with key #$test_num...\n";
    print "="x70 . "\n";
    
    # Change to openkore-master directory and run
    chdir('openkore-master') or die "Cannot cd to openkore-master: $!\n";
    
    # Run OpenKore and capture output
    my $timeout = 60; # 60 seconds timeout
    my $pid = fork();
    
    if ($pid == 0) {
        # Child process - run OpenKore
        exec('perl', 'openkore.pl');
        exit(0);
    } elsif ($pid > 0) {
        # Parent process - wait with timeout
        my $elapsed = 0;
        my $success = 0;
        
        while ($elapsed < $timeout) {
            sleep(5);
            $elapsed += 5;
            
            # Check if process is still running
            my $running = kill(0, $pid);
            
            if (!$running) {
                print "\n✓ OpenKore process ended\n";
                last;
            }
            
            print "    [${elapsed}s] Monitoring... (Ctrl+C to stop and try next key)\n";
        }
        
        # Kill the process if still running
        if (kill(0, $pid)) {
            print "\n    Timeout reached. Stopping OpenKore...\n";
            kill('TERM', $pid);
            sleep(2);
            kill('KILL', $pid) if kill(0, $pid);
        }
        
        waitpid($pid, 0);
        
        chdir('..') or die "Cannot cd back: $!\n";
        
        print "\n";
        print "="x70 . "\n";
        print "Did authentication succeed? (yes/no): ";
        my $answer = <STDIN>;
        chomp($answer);
        
        if ($answer =~ /^y/i) {
            print "\n";
            print "="x70 . "\n";
            print "SUCCESS! Key #$test_num works!\n";
            print "Key: $key\n";
            print "="x70 . "\n";
            print "\nThe config file has been updated with the working key.\n";
            print "You can now run OpenKore normally.\n\n";
            exit(0);
        }
    } else {
        die "Failed to fork: $!\n";
    }
    
    chdir('..') if (-d '../openkore-master');
}

print "\n";
print "="x70 . "\n";
print "All keys tested. None worked.\n";
print "="x70 . "\n";
print "\nPossible issues:\n";
print "1. None of the extracted keys are correct\n";
print "2. The server uses a different authentication protocol\n";
print "3. Additional server-side validation is required\n";
print "\nTo restore original config: cp $backup_file $config_file\n\n";
