# How to Extract Gepard Key from Client

## Step 1: Download and Extract Client

1. Download the Arkangel RO client from the provided link
2. Extract `ArkangelSEA Official.rar` to this directory
3. The extracted folder should contain `gepard.dll`

## Step 2: Extract the Encryption Key

### Option A: Automated Extraction (Try First)

Run the key extractor script:

```bash
perl extract_key.pl
```

This will:
- Locate gepard.dll in the extracted client
- Analyze the DLL for potential encryption keys
- Show top candidates based on entropy analysis
- Provide hex strings you can test

### Option B: Manual Extraction (More Reliable)

#### Using a Debugger (Recommended)

1. **Install a debugger:**
   - Windows: x64dbg (https://x64dbg.com/)
   - Cross-platform: Ghidra (https://ghidra-sre.org/)

2. **Find AES functions:**
   - Load gepard.dll in the debugger
   - Search for imports: `AES_*`, `rijndael_*`, `CryptEncrypt`
   - Look for strings like "AES", "Rijndael", encryption-related text

3. **Set breakpoints:**
   - Set breakpoint on AES encryption function
   - Run Arkangel RO client
   - Trigger authentication (login to server)
   - When breakpoint hits, examine the parameters

4. **Extract the key:**
   - The key is usually passed as a parameter
   - Look for 16, 24, or 32 byte buffers
   - Dump the memory and save the hex value

#### Using Memory Scanning

1. **Run the client and login**
2. **Attach Process Explorer or similar tool**
3. **Search for known patterns:**
   - If you have a challenge/response pair from packet capture
   - Search memory for those byte sequences
   - The key should be nearby in memory

#### Using Cheat Engine (Simple Method)

1. Download Cheat Engine
2. Attach to RO client process
3. Do a "Scan for unknown initial value"
4. Login to trigger Gepard authentication
5. Scan for "Changed value"
6. Repeat to narrow down to encryption-related memory
7. Examine the memory regions that changed

## Step 3: Test the Key

Once you have a potential key:

1. **Edit config.txt:**
   ```ini
   gepard_key YOUR_HEX_KEY_HERE
   ```

2. **Verify configuration:**
   ```bash
   perl check_config.pl
   ```

3. **Test encryption:**
   ```bash
   perl test_encryption.pl
   ```

4. **Test connection:**
   ```bash
   cd openkore-master
   perl openkore.pl
   ```

5. **Check logs for:**
   ```
   [GepardShield] Encryption initialized successfully
   [GepardShield] Challenge decrypted successfully
   [GepardShield] Response encrypted successfully
   ```

## Step 4: If Key Extraction Fails

### Alternative: Network Packet Analysis

1. **Capture packets with Wireshark:**
   - Filter: `tcp.port == 6955`
   - Look for packet 0x4753 (Gepard challenge)
   - Capture both challenge and response

2. **Analyze patterns:**
   - Challenge is 32+ bytes encrypted
   - Response is similar size
   - Both use the same key

3. **Brute force approach (advanced):**
   - If you have multiple challenge/response pairs
   - Can attempt to derive the key mathematically
   - Requires cryptanalysis knowledge

### Contact Server Administrator

If reverse engineering is not working:
1. Contact the Arkangel RO server administrator
2. Ask if they allow third-party clients like OpenKore
3. Request the Gepard encryption key
4. This is the easiest and most legal method

## Security Notice

**IMPORTANT:** Only extract encryption keys from servers where:
1. You have explicit permission to use third-party clients
2. You are the server administrator testing security
3. Reverse engineering is legally permitted in your jurisdiction

Do not:
- Share extracted keys publicly
- Use keys to bypass anti-cheat on servers that prohibit it
- Violate any terms of service

## Troubleshooting

### "gepard.dll not found"
- Make sure you extracted the client to the right location
- Check that the file is actually named `gepard.dll` (not `GEPARD.DLL` or similar)
- Try placing it in the root directory of this repository

### "No potential keys found"
- The DLL may be packed/encrypted itself
- Try using a proper debugger instead of static analysis
- Consider dynamic analysis while the client is running

### "Wrong key" when connecting
- The key you extracted might be wrong
- Try other candidates from the extractor
- Verify you're using the hex format correctly
- Make sure there are no spaces in the hex string

## Files in This Repository

- `extract_key.pl` - Automated key extraction tool
- `test_encryption.pl` - Test encryption module
- `check_config.pl` - Verify configuration
- `QUICKSTART.md` - General setup guide
- `PROJECT_COMPLETE.md` - Implementation status

## Support

If you need help:
1. Check the debug logs from OpenKore
2. Run `perl check_config.pl` to verify setup
3. Make sure gepard_debug is enabled
4. Look for error messages in the output

---

**Status**: Ready to extract key once client is downloaded
**Tools**: extract_key.pl, debugger recommendations provided
**Next**: Download client, run extractor, test key
