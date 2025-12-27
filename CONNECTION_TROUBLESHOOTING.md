# Connection Troubleshooting Guide

## Issue: "Connecting (104.234.180.123:6955)... couldn't connect: Connection timed out"

This error means OpenKore cannot establish a TCP connection to the Arkangel RO server.

## Root Causes

### 1. Network Connectivity Issues

**Symptoms:**
```
Connecting (104.234.180.123:6955)... couldn't connect: Connection timed out (error code 110)
```

**Causes:**
- Firewall blocking outgoing connections on port 6955
- ISP blocking game server ports
- Server is down or maintenance
- Wrong server IP/port configuration
- Geographic restrictions or IP whitelist

**Solutions:**

#### A. Test Network Connectivity

```bash
# Test if server is reachable
ping 104.234.180.123

# Test if port is open
nc -zv 104.234.180.123 6955
# or
telnet 104.234.180.123 6955
```

**Expected output if working:**
```
Connection to 104.234.180.123 6955 port [tcp/*] succeeded!
```

**If timeout occurs:**
- Server may be blocking your IP
- Firewall blocking the connection
- Server is down

#### B. Check Firewall

**Linux:**
```bash
# Check iptables rules
sudo iptables -L -n

# Allow outgoing connections on port 6955
sudo iptables -A OUTPUT -p tcp --dport 6955 -j ACCEPT

# Check UFW (if installed)
sudo ufw status
sudo ufw allow out 6955/tcp
```

**Windows:**
```
1. Open Windows Firewall settings
2. Allow OpenKore through firewall
3. Create outbound rule for port 6955
```

#### C. Check Server Status

1. Visit https://arkangelrosea.com/ to check if server is online
2. Check server status on their forums or Discord
3. Try logging in with official client first

#### D. Verify Configuration

Check `/home/runner/work/MDTOpenkore/MDTOpenkore/openkore-master/tables/servers.txt`:

```ini
[Arkangel RO]
ip 104.234.180.123
port 6955
master_version 1
version 55
serverType kRO_RagexeRE_2015_11_04a
serverEncoding Western
charBlockSize 144
private 1
addTableFolders iRO
recvpackets arkangel.txt
```

If server IP changed, update the `ip` field.

### 2. Incorrect Server Configuration

**Check config.txt:**
```ini
server Arkangel RO    # Must match [Arkangel RO] in servers.txt
```

### 3. VPN/Proxy Issues

If using VPN:
- Disconnect and try direct connection
- Try different VPN server location
- Some RO servers block VPN IPs

### 4. ISP Blocking Gaming Ports

Some ISPs block common gaming ports. Solutions:
- Contact ISP
- Use VPN (if server allows)
- Use mobile hotspot as test

## Step-by-Step Debugging

### Step 1: Verify OpenKore Builds Successfully

```bash
cd /home/runner/work/MDTOpenkore/MDTOpenkore/openkore-master
make clean && make
```

Should end with: `scons: done building targets.`

### Step 2: Test Encryption Module

```bash
cd /home/runner/work/MDTOpenkore/MDTOpenkore
perl test_encryption.pl
```

Should show: `All tests passed! CBC-AES encryption is working correctly.`

### Step 3: Test Network to Server

```bash
# Test ping
ping -c 4 104.234.180.123

# Test port
nc -zv -w 10 104.234.180.123 6955
```

If this fails, **connection issue is not OpenKore** - it's your network/firewall.

### Step 4: Try Official Client

Before troubleshooting OpenKore:
1. Download Arkangel RO official client
2. Try logging in with official client
3. If official client works but OpenKore doesn't → configuration issue
4. If official client fails too → server/network issue

### Step 5: Enable Debug Logging

Edit `openkore-master/control/config.txt`:

```ini
# Enable all debug output
gepard_debug 1
logConsole 1
logFile 1

# See all network packets
debugPacket_received 1
debugPacket_sent 1
```

Run OpenKore and check logs in `openkore-master/logs/`.

### Step 6: Test with Different Network

Try connecting from:
- Different computer
- Different location
- Mobile hotspot
- VPN

This helps identify if it's IP-based blocking.

## Common Error Messages

### "Connection timed out (error code 110)"
**Cause:** Cannot reach server
**Solution:** Check firewall, test with nc/telnet, verify server is up

### "Connection refused (error code 111)"
**Cause:** Server rejected connection
**Solution:** Wrong port, server down, or IP banned

### "No route to host (error code 113)"  
**Cause:** Network routing issue
**Solution:** Check network configuration, gateway, DNS

### "Network unreachable (error code 101)"
**Cause:** No network connectivity
**Solution:** Check internet connection, network interfaces

## Environment-Specific Issues

### GitHub Actions / CI Environment

The test environment may have network restrictions:
- Outbound connections limited
- Certain ports blocked
- Geographic restrictions

**Solution:** Test on local machine with proper network access.

### Docker Containers

If running in Docker:
- Use `--network host` mode
- Forward port 6955
- Check container network configuration

### Virtual Machines

- Verify network adapter is bridged (not NAT)
- Check VM firewall settings
- Ensure VM has internet access

## Alternative: Check if Server Changed

Server configurations can change. Check these sources for updates:

1. **Official Website:** https://arkangelrosea.com/
2. **Forums/Discord:** Look for server IP changes
3. **Patcher:** Check patch files for updated server info
4. **Community:** Ask other players if they can connect

## Testing Different Encryption Keys

If network is fine but authentication fails:

```bash
cd /home/runner/work/MDTOpenkore/MDTOpenkore/openkore-master/control
cp config.txt config.txt.backup

# Edit config.txt and try backup keys one by one:
# Key 1: d150f7d25803840452acdc9423ca66c1 (current)
# Key 2: 50f7d25803840452acdc9423ca66c1a4
# Key 3: 6a878404d2823ba4c16c2400da894c25
# Key 4: c6044c3e0fbe140cc0cae533c366f7d9
# Key 5: 044c3e0fbe140cc0cae533c366f7d9e8
```

## Success Indicators

When connection works, you'll see:

```
Connecting to Account Server...
Connecting (104.234.180.123:6955)... connected
Gepard Shield detected!
Gepard Shield: Received challenge packet
Gepard Shield: Challenge decrypted successfully
Gepard Shield: Sending encrypted response
Received character list
Received character list
Sending character login request...
Connected to Map Server
```

No "timeout", "refused", or "attempting" messages.

## Getting Help

If still stuck:

1. **Collect Information:**
   - OpenKore version output
   - Full error messages from console
   - Network test results (ping, nc output)
   - Official client works? Yes/No
   
2. **Check Logs:**
   - `openkore-master/logs/console.txt`
   - `openkore-master/logs/packet.log`
   
3. **Forum/Discord:**
   - Post the error message
   - Include network test results
   - Mention if official client works

## Summary

**Most common cause:** Firewall or network blocking port 6955

**Quick test:**
```bash
nc -zv 104.234.180.123 6955
```

If this times out, the problem is network/firewall, not OpenKore configuration.
