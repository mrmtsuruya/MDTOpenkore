# Complete Login Flow for Arkangel RO

## Overview

This document explains the complete login flow that OpenKore will execute when connecting to Arkangel RO with the configured test account.

## Configuration Summary

```ini
Server: Arkangel RO (104.234.180.123:6955)
Username: Rakshot26
Password: Akemi_2689
Character: Slot 0 (first character)
PIN Code: 0926
Encryption: d150f7d25803840452acdc9423ca66c1
```

## Login Flow Steps

### 1. Server Selection
```
OpenKore loads and displays master server list
Auto-selects: Arkangel RO (configured in config.txt)
```

### 2. Plugin Loading
```
✅ Loading 14 plugins...
   - GepardShield.pl (for anti-cheat authentication)
   - reconnect.pl (for automatic reconnection)
   - eventMacro.pl, macro.pl (for automation)
   - And 10 more plugins...
All plugins loaded successfully!
```

### 3. Table Loading
```
✅ Loading 50+ table files...
   - items.txt, itemslots.txt, maps.txt
   - skillnametable.txt, spells.txt
   - portals.txt, monsters.txt
   - And 40+ more tables...
All tables loaded successfully!
```

### 4. Connection to Account Server
```
Connecting to Account Server...
Connecting (104.234.180.123:6955)...
```

**What happens:**
- OpenKore establishes TCP connection to game server
- Sends master login packet
- Waits for server response

### 5. Gepard Shield Challenge (if received)
```
[GepardShield] Received packet 0x4753
[GepardShield] Challenge length: XX bytes
[GepardShield] Challenge data (hex): XXXXXXXX...
```

**What happens:**
- Server sends encrypted Gepard Shield challenge
- GepardShield plugin intercepts packet 0x4753
- Plugin calls gepard_decrypt_challenge()
- Decrypts using CBC-AES with configured key
- Generates appropriate response
- Encrypts response using gepard_encrypt_response()
- Sends back to server

**Debug output (if gepard_debug=1):**
```
[GepardCrypto] Decrypting challenge...
[GepardCrypto] Plaintext (hex): XXXXXXXX...
[GepardCrypto] Generating response...
[GepardCrypto] Encrypting response...
[GepardCrypto] Ciphertext (hex): XXXXXXXX...
```

### 6. Account Authentication
```
Sending account login...
Username: Rakshot26
Password: (encrypted)
```

**What happens:**
- OpenKore sends login credentials
- Server validates username/password
- If Gepard Shield is satisfied, proceeds to character selection
- If Gepard Shield fails, connection is rejected

**Possible outcomes:**
- ✅ **Success**: Receives character list
- ❌ **Wrong credentials**: "Account doesn't exist" or "Incorrect password"
- ❌ **Gepard failure**: Connection dropped or "Anti-cheat detection"
- ❌ **Wrong key**: Connection timeout or silent rejection

### 7. Character Selection
```
Character List:
Slot 0: [Character Name] [Level] [Class]
Slot 1: (empty or another character)
Slot 2: (empty or another character)

Selecting character: Slot 0
```

**What happens:**
- Server sends list of characters on account
- OpenKore auto-selects slot 0 (first character)
- May require PIN code if server has PIN system enabled

### 8. PIN Code Entry (if required)
```
Server requests PIN code...
Sending PIN: 0926
```

**What happens:**
- Some servers require 4-digit PIN for character selection
- OpenKore automatically sends configured PIN (0926)
- Server validates PIN
- If correct, proceeds to character login

**Possible outcomes:**
- ✅ **Correct PIN**: Character login proceeds
- ❌ **Wrong PIN**: "Incorrect PIN" or character selection fails
- ⚠️ **No PIN required**: This step is skipped

### 9. Map Server Connection
```
Received character ID from Account Server.
Connecting to Map Server...
Connecting (104.234.180.123:XXXX)...
Connected!
```

**What happens:**
- Account server provides map server IP and session token
- OpenKore connects to map server
- Sends session token for verification
- Map server validates and loads character

### 10. Character Login Complete
```
----------------------------
Character loaded successfully!
----------------------------
Name: [Character Name]
Level: XX
Class: [Job Class]
Map: prontera (or last saved location)
HP: XXXX/XXXX
SP: XXX/XXX
```

**What happens:**
- Character data is loaded
- Inventory, skills, equipment loaded
- Map loaded
- Character appears in game world
- AI begins operating based on config

## Troubleshooting

### If Connection Times Out

**Likely causes:**
1. **Firewall**: Port 6955 blocked
2. **Network restrictions**: Server IP blocked
3. **Server down**: Arkangel RO offline

**Solution:**
- Test from different network
- Check server status at https://arkangelrosea.com/
- Verify port 6955 is accessible

### If Gepard Shield Fails

**Symptoms:**
```
Connecting (104.234.180.123:6955)...
Connected!
(immediate disconnect or timeout)
```

**Likely causes:**
1. **Wrong encryption key**
2. **Incorrect response format**
3. **Server updated Gepard version**

**Solution:**
Try backup encryption keys:
```bash
# Edit config.txt and replace gepard_key with:
gepard_key 50f7d25803840452acdc9423ca66c1a4  # Backup #1
gepard_key 6a878404d2823ba4c16c2400da894c25  # Backup #2
gepard_key c6044c3e0fbe140cc0cae533c366f7d9  # Backup #3
```

### If Login Fails

**Symptoms:**
```
Account doesn't exist
Incorrect password
This ID is already logged in
```

**Solutions:**
- Verify username/password correct
- Check if account banned
- Wait if "already logged in" (try again in 5 minutes)
- Create new account if needed

### If PIN Code Fails

**Symptoms:**
```
Incorrect PIN code
Character selection failed
```

**Solutions:**
- Verify PIN is correct (check with web account panel)
- Update config.txt with correct PIN
- Contact server admin if PIN forgotten

### If Character Loads But Disconnects

**Symptoms:**
```
Character loaded successfully!
(immediate disconnect)
```

**Likely causes:**
1. **Server-side anti-bot detection**
2. **Suspicious behavior patterns**
3. **Account flagged**

**Solutions:**
- Add delays to automation
- Reduce AI aggressiveness
- Contact server admin

## Expected Behavior on Successful Login

When everything works correctly, you should see:

```
*** OpenKore what-will-become-2.1 ***
***   https://openkore.com/   ***

Selectively loading plugins...
[All plugins load successfully]

Loading control/config.txt...
[All configuration loaded]

Loading tables/servers.txt...
[Arkangel RO auto-selected]

Connecting to Account Server...
Connecting (104.234.180.123:6955)... connected
[GepardShield] Authentication successful
Account login successful
Character selection successful
PIN code accepted
Connecting to Map Server... connected
Character loaded successfully!

----------------------------
Rakshot26 (Level XX [Class])
Map: prontera
HP: XXXX/XXXX SP: XXX/XXX
----------------------------

AI: enabled
Bot is now active and following configured behavior!
```

## Monitoring During Test

### Key Things to Watch

1. **Plugin Loading**
   - All 14 plugins should load without errors
   - Especially watch for GepardShield.pl

2. **Connection Status**
   - "Connecting... connected" means TCP connection works
   - "Connecting... timeout" means network issue

3. **Gepard Messages**
   - Look for "[GepardShield]" messages
   - Should see challenge received and response sent
   - If no messages, packet 0x4753 not received (might not be required)

4. **Authentication**
   - "Account login successful" = credentials correct
   - "Character selection successful" = character loaded
   - "PIN code accepted" = PIN correct

5. **Debug Output**
   - With `gepard_debug 1`, you'll see hex dumps
   - Shows encryption/decryption working
   - Useful for diagnosing key issues

## Testing Checklist

Before declaring success, verify:

- [ ] OpenKore loads without errors
- [ ] All plugins load successfully
- [ ] Connection reaches server (not timeout)
- [ ] Gepard Shield authentication passes (if required)
- [ ] Account login succeeds
- [ ] Character selection works
- [ ] PIN code accepted (if required)
- [ ] Map server connection established
- [ ] Character fully loaded in game world
- [ ] AI starts operating
- [ ] Character can move/interact in game

## Next Steps After Successful Login

Once logged in successfully:

1. **Test Basic Functions**
   - Character movement
   - Item pickup
   - Skill usage
   - Chat commands

2. **Configure AI Behavior**
   - Edit config.txt for desired behavior
   - Set up macros if needed
   - Configure combat settings

3. **Monitor Stability**
   - Watch for disconnections
   - Check for Gepard re-challenges
   - Verify encryption stays working

4. **Fine-tune Settings**
   - Adjust attack/skill macros
   - Configure item management
   - Set up auto-storage

## Support

If issues persist:

1. **Check Logs**
   - Review full output in terminal
   - Look for error messages
   - Check gepard debug output

2. **Test Encryption**
   ```bash
   perl test_encryption.pl
   ```
   All tests should pass.

3. **Verify Configuration**
   ```bash
   perl check_config.pl
   ```
   Should report no errors.

4. **Try Backup Keys**
   19 backup encryption key candidates available
   Test each until one works

5. **Contact Server Admin**
   - If Gepard Shield blocks you
   - If account issues
   - For server-specific help

---

**System Status**: Fully configured and ready for testing!
**Last Updated**: 2025-12-27
**Configuration Version**: v17 (commit c270d74)
