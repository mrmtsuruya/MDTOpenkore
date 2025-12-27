#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use Time::HiRes qw(time);

print "=" x 70 . "\n";
print "Arkangel RO Connection Diagnostic Tool\n";
print "=" x 70 . "\n\n";

my $server_ip = "104.234.180.123";
my $server_port = 6955;
my $timeout = 10;

# Test 1: DNS Resolution
print "[Test 1/5] DNS Resolution Test\n";
print "-" x 70 . "\n";
print "Resolving arkangelrosea.com...\n";
my $dns_result = `host arkangelrosea.com 2>&1`;
if ($dns_result =~ /has address/) {
    print "✓ DNS resolution: SUCCESS\n";
    print "$dns_result\n";
} else {
    print "✗ DNS resolution: FAILED or not configured\n";
    print "This is OK if connecting directly to IP\n\n";
}

# Test 2: ICMP Ping
print "\n[Test 2/5] ICMP Ping Test\n";
print "-" x 70 . "\n";
print "Pinging $server_ip (4 packets)...\n";
my $ping_result = `ping -c 4 -W 5 $server_ip 2>&1`;
if ($ping_result =~ /(\d+) received/) {
    my $received = $1;
    if ($received > 0) {
        print "✓ Ping: SUCCESS ($received/4 packets received)\n";
        if ($ping_result =~ /time=(\d+\.?\d*) ms/) {
            print "  Average latency: $1 ms\n";
        }
    } else {
        print "✗ Ping: FAILED (0 packets received)\n";
        print "  Server may be blocking ICMP or network is unreachable\n";
    }
} else {
    print "✗ Ping: ERROR\n";
    print "$ping_result\n";
}

# Test 3: TCP Connection
print "\n[Test 3/5] TCP Port Connection Test\n";
print "-" x 70 . "\n";
print "Attempting to connect to $server_ip:$server_port...\n";

my $start_time = time();
my $socket = IO::Socket::INET->new(
    PeerAddr => $server_ip,
    PeerPort => $server_port,
    Proto    => 'tcp',
    Timeout  => $timeout,
);

my $elapsed = time() - $start_time;

if ($socket) {
    print "✓ TCP Connection: SUCCESS!\n";
    printf "  Connection established in %.2f seconds\n", $elapsed;
    print "  Local address: " . $socket->sockhost() . ":" . $socket->sockport() . "\n";
    print "  Remote address: " . $socket->peerhost() . ":" . $socket->peerport() . "\n";
    close($socket);
} else {
    print "✗ TCP Connection: FAILED!\n";
    printf "  Timeout after %.2f seconds\n", $elapsed;
    print "  Error: $!\n";
    print "\n";
    print "  This means OpenKore CANNOT connect to the server.\n";
    print "  Possible causes:\n";
    print "    - Server is down or in maintenance\n";
    print "    - Firewall is blocking port $server_port\n";
    print "    - Your IP is blocked by the server\n";
    print "    - ISP is blocking gaming ports\n";
    print "    - Network routing issue\n";
}

# Test 4: Alternative Port Test (using netcat if available)
print "\n[Test 4/5] Advanced Port Scan\n";
print "-" x 70 . "\n";
my $nc_available = `which nc 2>&1`;
if ($nc_available && $nc_available =~ /\/nc/) {
    print "Testing with netcat...\n";
    my $nc_result = `timeout $timeout nc -zv $server_ip $server_port 2>&1`;
    print "$nc_result\n";
    if ($nc_result =~ /succeeded|open/) {
        print "✓ Netcat test: Port is OPEN\n";
    } else {
        print "✗ Netcat test: Port appears CLOSED or filtered\n";
    }
} else {
    print "Netcat not available, skipping\n";
}

# Test 5: Firewall Check
print "\n[Test 5/5] Local Firewall Check\n";
print "-" x 70 . "\n";

# Check for common firewall tools
my $has_iptables = -x "/sbin/iptables" || -x "/usr/sbin/iptables";
my $has_ufw = -x "/usr/sbin/ufw";

if ($has_iptables) {
    print "iptables detected, checking OUTPUT rules...\n";
    my $ipt_result = `sudo iptables -L OUTPUT -n 2>&1 | head -20`;
    if ($ipt_result =~ /tcp dpt:$server_port.*DROP/) {
        print "✗ WARNING: iptables may be DROPPING connections to port $server_port\n";
    } elsif ($ipt_result =~ /tcp dpt:$server_port.*ACCEPT/) {
        print "✓ iptables allows connections to port $server_port\n";
    } else {
        print "ℹ No specific rules found for port $server_port\n";
    }
}

if ($has_ufw) {
    print "\nUFW detected, checking status...\n";
    my $ufw_result = `sudo ufw status 2>&1`;
    print "$ufw_result\n";
}

if (!$has_iptables && !$has_ufw) {
    print "No common firewall tools detected (iptables, ufw)\n";
}

# Summary
print "\n" . "=" x 70 . "\n";
print "DIAGNOSTIC SUMMARY\n";
print "=" x 70 . "\n\n";

if ($socket) {
    print "✓✓✓ CONNECTION TEST: PASSED ✓✓✓\n\n";
    print "Your network can reach the Arkangel RO server!\n";
    print "If OpenKore still fails to connect, the issue is likely:\n";
    print "  - Configuration error in config.txt or servers.txt\n";
    print "  - Wrong encryption key (try backup keys)\n";
    print "  - Server-side authentication issue\n";
    print "  - Gepard Shield blocking the connection\n\n";
    print "Next steps:\n";
    print "  1. Verify config.txt has correct credentials\n";
    print "  2. Check gepard_key is set correctly\n";
    print "  3. Enable debug mode: gepard_debug 1\n";
    print "  4. Run: cd openkore-master && perl openkore.pl\n";
} else {
    print "✗✗✗ CONNECTION TEST: FAILED ✗✗✗\n\n";
    print "Your network CANNOT reach the Arkangel RO server.\n";
    print "This is NOT an OpenKore configuration issue.\n\n";
    print "Required actions:\n";
    print "  1. Check if server is online at https://arkangelrosea.com/\n";
    print "  2. Test from a different network (mobile hotspot, different WiFi)\n";
    print "  3. Check firewall settings:\n";
    print "     - Windows: Allow openkore.pl through Windows Firewall\n";
    print "     - Linux: sudo ufw allow out $server_port/tcp\n";
    print "  4. Contact your ISP if they're blocking gaming ports\n";
    print "  5. Try using a VPN (if server allows)\n";
    print "  6. Ask server admins if your IP is blocked\n\n";
    print "Alternative test:\n";
    print "  - Try connecting with official Arkangel RO client\n";
    print "  - If official client works, report OpenKore version/logs to devs\n";
    print "  - If official client fails too, it's a network/server issue\n";
}

print "\nFor detailed troubleshooting, see: CONNECTION_TROUBLESHOOTING.md\n";
print "=" x 70 . "\n";
