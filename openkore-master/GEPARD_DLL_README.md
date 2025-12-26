# Gepard Shield DLL Integration Guide

This document explains how to use a custom Gepard Shield DLL with OpenKore for servers that use Gepard anti-cheat protection.

## Overview

OpenKore now supports loading an external DLL to handle Gepard Shield authentication challenges. When the server sends packet 0x4753 (Gepard challenge), OpenKore will:
1. Load your custom `gepard.dll`
2. Pass the challenge data to your DLL
3. Send the DLL's response back to the server

## Configuration

### 1. Enable Gepard Support in config.txt

Add these lines to your `control/config.txt`:

```
# Gepard Shield settings
gepard_enabled 1
gepard_dll gepard.dll
```

**Options:**
- `gepard_enabled`: Set to `1` to enable Gepard DLL support, `0` to disable (default: 0)
- `gepard_dll`: Filename of your Gepard DLL (default: gepard.dll)

### 2. Create Your Gepard DLL

Your DLL must export a function with this signature:

```cpp
extern "C" __declspec(dllexport) int gepard_process_challenge(
    unsigned char* challenge_data,  // Input: Challenge data from server (32 bytes)
    int challenge_length,            // Input: Length of challenge data
    unsigned char* response_buffer   // Output: Buffer to write response (allocate 64 bytes)
);
```

**Function Requirements:**
- **Input**: `challenge_data` contains the 32-byte challenge from the server
- **Input**: `challenge_length` is the length of the challenge (typically 32)
- **Output**: Write your response to `response_buffer`
- **Return**: Number of bytes written to `response_buffer`, or negative value on error

### 3. DLL Implementation Example

Here's a skeleton C++ implementation:

```cpp
#include <windows.h>

extern "C" __declspec(dllexport) int gepard_process_challenge(
    unsigned char* challenge_data,
    int challenge_length,
    unsigned char* response_buffer
) {
    // TODO: Implement your Gepard authentication logic here
    // 
    // This is where you would:
    // 1. Process the challenge_data using Gepard's algorithm
    // 2. Generate the appropriate response
    // 3. Write the response to response_buffer
    // 4. Return the length of the response
    
    // Example (this will NOT work - you need actual Gepard logic):
    if (challenge_length != 32) {
        return -1;  // Error: unexpected challenge length
    }
    
    // Your Gepard authentication code goes here
    // ...
    
    // For now, return error since this is just a template
    return -1;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    return TRUE;
}
```

### 4. Place Your DLL

Put your compiled `gepard.dll` in one of these locations:
- OpenKore root directory (recommended)
- `./src/` subdirectory
- Or specify full path in `gepard_dll` config option

## Testing

1. Enable debug mode in `config.txt`:
   ```
   debug 2
   debugPacket_received 1
   verbose 1
   ```

2. Run OpenKore and watch for these messages:
   ```
   Received account server intro packet (0x4753)
   Gepard Shield enabled, attempting to process challenge...
   Loading Gepard DLL from: ./gepard.dll
   Gepard DLL returned X bytes response
   Sent Gepard Shield response (0x4753)
   ```

3. If successful, the connection should proceed past the challenge phase

## Troubleshooting

### "Gepard DLL not found"
- Verify `gepard.dll` exists in the OpenKore directory
- Check the `gepard_dll` config option specifies the correct filename
- Try using an absolute path

### "Failed to load gepard_process_challenge function"
- Verify your DLL exports the function correctly
- Use a tool like `dumpbin /exports gepard.dll` to check exports
- Ensure function signature matches exactly

### "Gepard DLL returned error code: -1"
- Your DLL's `gepard_process_challenge` function returned an error
- Check your DLL's implementation
- Enable logging/debugging in your DLL to diagnose issues

### Connection still times out
- Verify your DLL is generating valid Gepard responses
- Check the server's expected response format
- Contact the server administrator for Gepard integration details

## Platform Support

**Windows Only**: Gepard DLL support currently only works on Windows due to:
- DLL format (Windows-specific)
- Win32::API requirement
- Gepard Shield itself being Windows-only

## Security Notice

- Creating Gepard authentication code may violate the server's Terms of Service
- This feature is provided for educational purposes and authorized testing only
- Always obtain permission from server administrators before using bot software
- Reverse-engineering anti-cheat systems may have legal implications

## Support

For issues with:
- **OpenKore integration**: Report in OpenKore issue tracker
- **DLL implementation**: This is user-provided code - consult Gepard documentation or server admin
- **Server-specific issues**: Contact the server administrator

## Technical Details

### Packet Flow

1. Client sends login packet (0x0064)
2. Server sends Gepard challenge (0x4753, 36 bytes: 2-byte header + 2-byte length + 32-byte challenge)
3. OpenKore receives challenge, extracts 32-byte challenge data
4. OpenKore calls `gepard_process_challenge()` in your DLL
5. OpenKore sends response packet (0x4753 + DLL response data)
6. Server validates response and proceeds with login

### Response Format

The response you generate should match what Gepard Shield expects. This varies by:
- Gepard Shield version
- Server configuration  
- Authentication method

Consult Gepard documentation or server admin for specifics.
