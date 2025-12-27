# Quick Start Guide for Arkangel RO

## Current Status

✅ **ALL ENCRYPTION IS WORKING!**

The GepardShield plugin is now fully functional with working CBC-AES encryption.

## What You Need

1. **Gepard Encryption Key** (REQUIRED)
   - Must be obtained from server administrator or reverse engineered from official client
   - Should be 16, 24, or 32 bytes (128, 192, or 256-bit)

2. **Login Credentials**
   - Username
   - Password
   - Character name

## Setup Instructions

### Step 1: Configure Your Credentials

Edit `openkore-master/control/config.txt`:

```ini
# Server Selection
server Arkangel RO

# YOUR CREDENTIALS HERE
username YOUR_USERNAME_HERE
password YOUR_PASSWORD_HERE
char YOUR_CHARACTER_NAME_HERE

# Gepard Shield (REQUIRED)
gepard_enabled 1
gepard_debug 1

# ENCRYPTION KEY (MUST BE SET)
gepard_key YOUR_HEX_KEY_HERE

# XKore Mode
XKore 2
```

### Step 2: Set the Encryption Key

The `gepard_key` can be in hex format:
```ini
gepard_key 0123456789ABCDEF0123456789ABCDEF
```

Or as a direct string (not recommended):
```ini
gepard_key \x01\x23\x45\x67\x89\xAB\xCD\xEF...
```

### Step 3: Run OpenKore

On Linux:
```bash
cd openkore-master
perl openkore.pl
```

On Windows:
```cmd
wxstart.exe
```

## What to Expect

With debug mode enabled, you should see:

```
[GepardShield] Initializing Gepard Shield authentication...
[GepardShield] Encryption initialized successfully
[GepardShield] Using 128-bit key
[GepardShield] Received Gepard Shield challenge packet (0x4753) #1
[GepardShield] Challenge decrypted successfully (XX bytes)
[GepardShield] Response encrypted successfully (XX bytes)
[GepardShield] Sent Gepard Shield response
```

## Troubleshooting

### "No encryption key configured"
- You forgot to set `gepard_key` in config.txt
- Make sure it's a valid hex string

### "Failed to decrypt challenge"
- Wrong encryption key
- Get the correct key from the server operator

### "Connection timeout"
- Normal if authentication fails
- Could be wrong key or response format

### "Unknown switch: 4753"
- Shouldn't happen - this is fixed
- If it does, check that packet definitions are correct

## How to Get the Encryption Key

### Method 1: Ask Server Administrator
- Easiest and most legal method
- Only works if you have permission to use third-party clients

### Method 2: Reverse Engineer (Requires Authorization)
1. Download official Arkangel RO client from https://arkangelrosea.com/
2. Use a debugger (x64dbg, IDA Pro, etc.)
3. Look for AES/Rijndael function calls
4. Set breakpoints on crypto operations
5. Extract key from memory during authentication
6. **IMPORTANT**: Only do this if you have explicit permission!

### Method 3: Network Analysis (Advanced)
1. Capture packets with Wireshark during successful authentication
2. Analyze challenge/response pairs
3. Look for patterns
4. Requires deep cryptographic knowledge

## Testing the Encryption

You can test the encryption module independently:

```bash
cd /home/runner/work/MDTOpenkore/MDTOpenkore
perl test_encryption.pl
```

This verifies that the encryption is working correctly with a test key.

## Next Steps

1. **Get the encryption key** - This is the critical missing piece
2. **Configure your credentials** - Username, password, character
3. **Run OpenKore** - perl openkore.pl
4. **Monitor the logs** - Look for Gepard Shield messages
5. **Debug as needed** - Check for errors

## Files Modified

- `openkore-master/control/config.txt` - Configuration
- `openkore-master/plugins/GepardShield/GepardShield.pl` - Main plugin
- `openkore-master/plugins/GepardShield/GepardCrypto.pm` - Encryption module
- `test_encryption.pl` - Test script

## Technical Details

- **Encryption**: CBC mode with zero padding
- **Cipher**: AES (Rijndael)
- **Block Size**: 16 bytes
- **Library**: Crypt::Mode::CBC (CryptX)
- **Key Support**: 128, 192, 256-bit

## Support

If you encounter issues:

1. Enable debug mode: `gepard_debug 1`
2. Check the console output
3. Look for error messages
4. Verify your encryption key is correct
5. Make sure your credentials are valid

## License

This work is for educational and authorized testing purposes only.
Use responsibly and in accordance with applicable laws and terms of service.

---

**Status**: Ready for testing with actual encryption key
**Date**: December 27, 2025
**Implementation**: Complete
