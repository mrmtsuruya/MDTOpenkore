# Gepard Shield Integration Guide

## Table of Contents
1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Architecture](#architecture)
4. [Configuration](#configuration)
5. [Implementation Guide](#implementation-guide)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#faq)

---

## Overview

### What is Gepard Shield?

Gepard Shield is an anti-cheat protection system used by some Ragnarok Online private servers to prevent unauthorized clients and bots from connecting. It uses a challenge-response authentication mechanism with CBS-AES encryption.

### How It Works

1. **Server sends challenge**: When connecting, server sends packet `0x4753` with encrypted challenge data
2. **Client processes challenge**: Client must decrypt, process, and generate appropriate response
3. **Client sends response**: Encrypted response is sent back to server in same packet format
4. **Server validates**: If response is correct, authentication succeeds and login proceeds

### Current Implementation Status

| Component | Status | Description |
|-----------|--------|-------------|
| **Packet Handling** | ✅ Complete | Packet 0x4753 recognized and handled |
| **Plugin Framework** | ✅ Complete | Full plugin structure with hooks |
| **Configuration** | ✅ Complete | Config file support and options |
| **Debug Logging** | ✅ Complete | Detailed hex dumps and logging |
| **CBS-AES Encryption** | ❌ Not Implemented | Requires algorithm/keys |
| **Protocol Processing** | ❌ Not Implemented | Requires protocol specification |

---

## Quick Start

### Prerequisites

- OpenKore installed and working
- Arkangel RO server (or other Gepard-protected server) credentials
- Understanding that **full authentication requires CBS-AES implementation**

### Basic Setup

1. **Apply packet handling fixes** (already done):
   ```
   ✅ control/config.txt - XKore set to 2
   ✅ tables/servers.txt - Arkangel RO uses arkangel.txt
   ✅ src/Network/Receive.pm - account_server_intro handler
   ✅ src/Network/Receive/kRO/RagexeRE_2015_11_04a.pm - Packet 0x4753 definition
   ```

2. **Enable GepardShield plugin**:

   Add to `control/config.txt`:
   ```
   gepard_enabled 1
   gepard_debug 1
   ```

3. **Run OpenKore**:
   ```bash
   # On Windows
   wxstart.exe

   # On Linux/Mac
   perl openkore.pl
   ```

4. **Monitor Output**:
   ```
   [GepardShield] Initializing Gepard Shield authentication...
   [GepardShield] Received Gepard Shield challenge packet (0x4753) #1
   [GepardShield] Challenge data (hex): f77ffbce835979af393a5bcbe2baf779...
   [GepardShield] WARNING: CBS-AES decryption not implemented!
   [GepardShield] Failed to generate authentication response
   ```

### What Happens Now?

With the current framework:
- ✅ **Will NOT timeout** with "Unknown switch: 4753"
- ✅ **Will receive** and log the challenge packet
- ✅ **Will display** hex dump of challenge data
- ❌ **Will NOT authenticate** successfully (encryption not implemented)
- ⚠️ **Connection will timeout/fail** at authentication stage

---

## Architecture

### Plugin Structure

```
plugins/GepardShield/
├── GepardShield.pl         # Main plugin code
├── config_example.txt      # Configuration examples
└── README.md              # Plugin-specific documentation

openkore-master/
├── src/Network/Receive.pm  # Packet handler
└── src/Network/Receive/kRO/
    └── RagexeRE_2015_11_04a.pm  # Packet definition
```

### Data Flow

```
Server → 0x4753 Challenge → handleGepardChallenge()
                                ↓
                         validateChallenge()
                                ↓
                         decryptChallenge() [STUB]
                                ↓
                         processGepardProtocol() [STUB]
                                ↓
                         encryptResponse() [STUB]
                                ↓
                         sendGepardResponse()
                                ↓
Client → 0x4753 Response → Server
```

### Hook System

The plugin uses OpenKore's hook system:

| Hook | Purpose |
|------|---------|
| `start3` | Initialize on OpenKore startup |
| `packet/account_server_intro` | Handle 0x4753 packet |
| `serverConnect/master` | Reset state on connection |
| `serverDisconnect` | Clean up on disconnect |
| `configModify` | React to config changes |

---

## Configuration

### Basic Options

```ini
# Enable/disable the plugin
gepard_enabled 1

# Enable debug logging (shows hex dumps)
gepard_debug 1

# Path to external Gepard DLL (optional)
gepard_dll_path gepard.dll
```

### Advanced Options

```ini
# Encryption key (implementation-dependent)
gepard_key YOUR_KEY_HERE

# Protocol version
gepard_protocol_version 1

# Max authentication retries
gepard_max_retries 3

# Response timeout in seconds
gepard_response_timeout 10
```

### Complete Arkangel RO Example

```ini
# Server selection
server Arkangel RO

# Login credentials
username your_username
password your_password
char your_character_name

# Gepard Shield settings
gepard_enabled 1
gepard_debug 1

# XKore mode (required for Arkangel RO)
XKore 2

# Other recommended settings
debug 2
verbose 1
```

---

## Implementation Guide

### What Needs to Be Implemented

To make authentication work, you must implement:

#### 1. CBS-AES Decryption (`decryptChallenge`)

```perl
sub decryptChallenge {
    my ($challenge) = @_;

    # IMPLEMENT: CBS-AES decryption
    # - Initialize AES cipher with proper key
    # - Set up Cipher Block Stealing (CBS) mode
    # - Decrypt 32-byte challenge
    # - Verify integrity (if applicable)

    my $key = "...";  # Obtain Gepard key
    my $decrypted = CBS_AES_Decrypt($challenge, $key);

    return $decrypted;
}
```

**Resources needed:**
- Gepard encryption key
- AES initialization vector (IV)
- CBS mode specification
- Padding/unpadding algorithm

#### 2. Protocol Processing (`processGepardProtocol`)

```perl
sub processGepardProtocol {
    my ($decrypted_data) = @_;

    # IMPLEMENT: Gepard protocol handling
    # - Parse decrypted challenge structure
    # - Extract nonce, timestamp, session data
    # - Generate appropriate response
    # - Include client proof/signature

    my $response = {
        nonce => extract_nonce($decrypted_data),
        timestamp => time(),
        client_id => generate_client_id(),
        proof => generate_proof($decrypted_data),
    };

    return encode_response($response);
}
```

**Resources needed:**
- Challenge packet format specification
- Response packet format specification
- Nonce/timestamp handling rules
- Client identification method

#### 3. CBS-AES Encryption (`encryptResponse`)

```perl
sub encryptResponse {
    my ($response_data) = @_;

    # IMPLEMENT: CBS-AES encryption
    # - Mirror of decryption process
    # - Encrypt response data
    # - Add integrity check (if applicable)

    my $key = "...";  # Same key as decryption
    my $encrypted = CBS_AES_Encrypt($response_data, $key);

    return $encrypted;
}
```

### Implementation Approaches

#### Option A: Pure Perl Implementation

**Pros:**
- No external dependencies
- Cross-platform
- Easy to debug

**Cons:**
- Slower performance
- More code to write

**Example:**
```perl
use Crypt::Cipher::AES;
use Crypt::Mode::CBC;  # Or custom CBS mode

sub decryptChallenge {
    my ($challenge) = @_;

    my $key = pack("H*", "your_hex_key");
    my $iv = pack("H*", "your_hex_iv");

    my $aes = Crypt::Mode::CBC->new('AES');
    my $decrypted = $aes->decrypt($challenge, $key, $iv);

    # Additional CBS mode handling...

    return $decrypted;
}
```

#### Option B: External DLL/Library

**Pros:**
- Can use existing Gepard DLL
- Faster performance
- Less implementation work

**Cons:**
- Platform-specific
- Requires DLL/library file
- More complex setup

**Example:**
```perl
use Win32::API;  # Windows
# or
use FFI::Raw;    # Cross-platform FFI

sub loadGepardDLL {
    my ($dll_path) = @_;

    $gepard_decrypt = Win32::API->new(
        $dll_path, 'DecryptChallenge', 'PP', 'I'
    );

    $gepard_encrypt = Win32::API->new(
        $dll_path, 'EncryptResponse', 'PP', 'I'
    );

    return 1;
}

sub decryptChallenge {
    my ($challenge) = @_;

    my $output_buffer = "\0" x 128;
    my $result = $gepard_decrypt->Call($challenge, $output_buffer);

    return $result ? $output_buffer : undef;
}
```

### Reverse Engineering Approach

If implementing from scratch:

1. **Capture Network Traffic**
   - Use Wireshark to capture successful authentication
   - Filter for packet 0x4753
   - Save challenge and response pairs

2. **Analyze Patterns**
   ```
   Challenge: 53 47 24 00 F7 7F FB CE 83 59 79 AF...
   Response:  53 47 24 00 [encrypted_response]...
   ```

3. **Test Hypotheses**
   - Try standard AES modes (CBC, ECB, CTR)
   - Test different key lengths (128, 192, 256 bit)
   - Look for magic bytes or headers

4. **Validate**
   - Test response against live server
   - Verify with multiple challenge/response pairs
   - Ensure consistency

---

## Troubleshooting

### Common Issues

#### 1. "Unknown switch: 4753"

**Symptom:** Error message about unknown packet
**Cause:** Packet handler not properly installed
**Solution:**
```bash
# Verify these files have the fixes:
- src/Network/Receive.pm (account_server_intro function)
- src/Network/Receive/kRO/RagexeRE_2015_11_04a.pm (packet definition)
- tables/servers.txt (recvpackets arkangel.txt)
```

#### 2. "Timeout on Account Server"

**Symptom:** Connection times out waiting for response
**Cause:** CBS-AES encryption not implemented
**Solution:** This is expected until encryption is implemented

#### 3. Plugin Not Loading

**Symptom:** No GepardShield messages in log
**Cause:** Plugin not in correct directory or not enabled
**Solution:**
```bash
# Check plugin location:
plugins/GepardShield/GepardShield.pl

# Verify in config.txt:
gepard_enabled 1
```

#### 4. Challenge Data Not Displaying

**Symptom:** No hex dump of challenge
**Cause:** Debug mode not enabled
**Solution:**
```ini
gepard_debug 1
debug 2
verbose 1
```

### Debug Mode Output

When `gepard_debug 1` is set, you'll see:

```
[GepardShield] Received Gepard Shield challenge packet (0x4753) #1
[GepardShield] Challenge length: 32 bytes
[GepardShield] Challenge data (hex): f77ffbce835979af393a5bcbe2baf779b58f8f548b5a362ed5a3ea00c04647e7
[GepardShield] Challenge breakdown:
[GepardShield]   0000: f7 7f fb ce 83 59 79 af  39 3a 5b cb e2 ba f7 79 .....Yy.9:[....y
[GepardShield]   0010: b5 8f 8f 54 8b 5a 36 2e  d5 a3 ea 00 c0 46 47 e7 ...T.Z6......FG.
```

This data is crucial for:
- Reverse engineering the encryption
- Testing your implementation
- Debugging issues

---

## FAQ

### Q: Will this work without implementing encryption?

**A:** No. The framework will:
- ✅ Recognize the packet
- ✅ Log the challenge
- ❌ NOT successfully authenticate

You must implement CBS-AES encryption for authentication to succeed.

### Q: Where can I get the encryption key?

**A:** The encryption key must be obtained through one of these methods:
1. Reverse engineer the official game client (requires authorization)
2. Obtain from server owner (if you have permission)
3. Find in publicly available documentation (if exists)

### Q: Can I use this on official Ragnarok Online servers?

**A:** No. This is designed for private servers that use Gepard Shield and where you have authorization to connect with third-party clients.

### Q: What is CBS mode?

**A:** Cipher Block Stealing is an encryption mode that allows encrypting data that's not a multiple of the block size without padding. It's similar to CBC mode but handles the final block differently.

### Q: How do I know if my implementation is correct?

**A:** Test against the live server:
1. Implement the encryption
2. Run OpenKore with `gepard_debug 1`
3. Check if authentication succeeds
4. Monitor for errors or disconnections

### Q: The plugin loads but I still get "Unknown switch: 4753"

**A:** This means the core packet handlers aren't installed. Make sure you've applied ALL the fixes:
```bash
git log --oneline
# Should show:
# - Fix packet 0x4753 handling and XKore configuration for Arkangel RO
# - Add GepardShield plugin framework for Arkangel RO
```

### Q: Can I contribute my encryption implementation?

**A:** Only if you have proper authorization and the implementation doesn't violate any terms of service. Consider:
- Do you have permission from the server owner?
- Is this for educational/research purposes?
- Are you the server owner testing your own security?

---

## Additional Resources

### Files Modified

| File | Changes | Purpose |
|------|---------|---------|
| `control/config.txt` | XKore 2 | Required for proper operation |
| `tables/servers.txt` | recvpackets arkangel.txt | Use correct packet definitions |
| `src/Network/Receive.pm` | account_server_intro handler | Handle packet 0x4753 |
| `src/Network/Receive/kRO/RagexeRE_2015_11_04a.pm` | Packet 0x4753 definition | Define packet structure |
| `plugins/GepardShield/GepardShield.pl` | Full plugin | Gepard Shield framework |

### Related Documentation

- [OpenKore Plugin Development](https://openkore.com/wiki/Plugin_Development)
- [OpenKore Network Subsystem](https://openkore.com/wiki/Network_subsystem)
- [AES Encryption](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
- [Cipher Block Stealing](https://en.wikipedia.org/wiki/Ciphertext_stealing)

### GitHub Issues

- [Issue #3: Implement Gepard Shield CBS-AES encryption](https://github.com/mrmtsuruya/MDTOpenkore/issues/3)
- [Issue #4: Test wxstart.exe connection to Arkangel RO](https://github.com/mrmtsuruya/MDTOpenkore/issues/4)

---

## License

This framework is provided as-is for educational and authorized testing purposes only. Use responsibly and in accordance with applicable laws and terms of service.

## Credits

- Framework created with Claude Code
- Based on OpenKore plugin architecture
- Inspired by LatamChecksum plugin implementation

---

**Last Updated:** December 27, 2025
**Version:** 1.0.0
**Status:** Framework Complete, Encryption Not Implemented
