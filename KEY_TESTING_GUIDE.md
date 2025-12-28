# Gepard Shield Key Testing Guide

## The Problem

OpenKore connects successfully and sends Gepard Shield responses, but the server times out. This suggests **the encryption key might be incorrect**.

## Quick Solution: Try Backup Keys

We extracted 20 potential keys from gepard.dll, ranked by entropy. The top key is configured, but if it doesn't work, try the backups.

---

## Method 1: Interactive Key Switcher (Recommended)

**Use the interactive script to quickly switch keys:**

```bash
cd ~/MDTOpenkore
./switch_key.sh
```

This script will:
- Show you all 5 top backup keys
- Let you choose which one to try
- Automatically update config.txt
- Tell you to run OpenKore again

After switching, test it:
```bash
cd openkore-master
perl openkore.pl
```

If authentication succeeds (you see "Received character list" instead of timeout), that key works!

---

## Method 2: Manual Editing with nano/vim

**Edit the config file directly:**

```bash
nano openkore-master/control/config.txt
```

Find the line:
```
gepard_key d150f7d25803840452acdc9423ca66c1
```

Replace with one of these backup keys:

**Top 5 backup keys to try (in order):**

1. `50f7d25803840452acdc9423ca66c1a4` (Key #2)
2. `6a878404d2823ba4c16c2400da894c25` (Key #3)
3. `c6044c3e0fbe140cc0cae533c366f7d9` (Key #4)
4. `044c3e0fbe140cc0cae533c366f7d9e8` (Key #5)
5. `44c3e0fbe140cc0cae533c366f7d9e89` (Key #6)

**Steps:**
1. Open file: `nano openkore-master/control/config.txt`
2. Find line: `gepard_key ...`
3. Replace the hex key with a backup key
4. Save: `Ctrl+O`, `Enter`, `Ctrl+X`
5. Test: `cd openkore-master && perl openkore.pl`

---

## Method 3: Quick One-Liner Command

**Try key #2:**
```bash
sed -i 's/^gepard_key .*/gepard_key 50f7d25803840452acdc9423ca66c1a4/' openkore-master/control/config.txt
cd openkore-master && perl openkore.pl
```

**Try key #3:**
```bash
sed -i 's/^gepard_key .*/gepard_key 6a878404d2823ba4c16c2400da894c25/' openkore-master/control/config.txt
cd openkore-master && perl openkore.pl
```

**Try key #4:**
```bash
sed -i 's/^gepard_key .*/gepard_key c6044c3e0fbe140cc0cae533c366f7d9/' openkore-master/control/config.txt
cd openkore-master && perl openkore.pl
```

---

## How to Know if a Key Works

**✅ SUCCESS (key is correct):**
```
[GepardShield] Received Gepard Shield challenge packet (0x4753) #1
[GepardShield] Authentication response sent successfully
Received character list          ← THIS LINE MEANS SUCCESS!
Character slot 0: [Character name]
```

**❌ FAILURE (key is wrong):**
```
[GepardShield] Received Gepard Shield challenge packet (0x4753) #1
[GepardShield] Authentication response sent successfully
[GepardShield] Received Gepard Shield challenge packet (0x4753) #2
[GepardShield] Authentication response sent successfully
Timeout on Account Server        ← THIS MEANS KEY IS WRONG
```

The server sends 2 challenges when the key is wrong, then times out.

---

## All 20 Backup Keys (Full List)

If top 5 don't work, try these:

```
1. d150f7d25803840452acdc9423ca66c1  (current - try first)
2. 50f7d25803840452acdc9423ca66c1a4
3. 6a878404d2823ba4c16c2400da894c25
4. c6044c3e0fbe140cc0cae533c366f7d9
5. 044c3e0fbe140cc0cae533c366f7d9e8
6. 44c3e0fbe140cc0cae533c366f7d9e89
7. 4c3e0fbe140cc0cae533c366f7d9e89e
8. c3e0fbe140cc0cae533c366f7d9e89e4
9. 3e0fbe140cc0cae533c366f7d9e89e49
10. e0fbe140cc0cae533c366f7d9e89e490
11. 0fbe140cc0cae533c366f7d9e89e4905
12. fbe140cc0cae533c366f7d9e89e49057
13. be140cc0cae533c366f7d9e89e490570
14. e140cc0cae533c366f7d9e89e4905701
15. 140cc0cae533c366f7d9e89e49057015
16. 40cc0cae533c366f7d9e89e490570150
17. 0cc0cae533c366f7d9e89e490570150f
18. cc0cae533c366f7d9e89e490570150f7
19. c0cae533c366f7d9e89e490570150f7d
20. 0cae533c366f7d9e89e490570150f7d2
```

---

## Troubleshooting

**Q: None of the keys work?**

A: Possible reasons:
1. Gepard Shield version changed (need to extract from newer gepard.dll)
2. Server uses custom protocol (not standard echo-back)
3. Additional validation required beyond encryption

**Q: How do I restore the original config?**

A: If you made a backup:
```bash
cp openkore-master/control/config.txt.backup openkore-master/control/config.txt
```

**Q: Can I automate testing all keys?**

A: Yes, but it's manual work. The `switch_key.sh` script makes it faster.

---

## Quick Reference Commands

**Check current key:**
```bash
grep gepard_key openkore-master/control/config.txt
```

**Backup config:**
```bash
cp openkore-master/control/config.txt openkore-master/control/config.txt.backup
```

**Restore config:**
```bash
cp openkore-master/control/config.txt.backup openkore-master/control/config.txt
```

**View full output (helpful for debugging):**
```bash
cd openkore-master
perl openkore.pl 2>&1 | tee ../openkore.log
```
