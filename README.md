# linux-lumia650

Porting mainline Linux to the Microsoft Lumia 650 (RM-1152, codename "Saana",
Qualcomm Snapdragon 212 / MSM8909, 32-bit ARM).

## Status

- [x] Bootloader unlocked with WPinternals 2.9.2 (see [UNLOCK.md](UNLOCK.md))
- [ ] Full eMMC backup
- [ ] Boot a kernel (based on [msm8916-mainline/linux](https://github.com/msm8916-mainline/linux))

## Contents

- `UNLOCK.md`: how the bootloader was unlocked, and the pitfalls hit along the way
- `tools/ffutool.py`: read-only inspector/extractor for Windows Phone FFU images
- `firmware/gpt-phone.txt`: the phone's eMMC partition table

Firmware images (FFU, emergency programmers, extracted partitions) aren't in
this repo because they're proprietary. Get them from the Internet Archive's
`W10M_FFUs` collection; `UNLOCK.md` has the paths and checksums.
