# Installing the Linux boot chain on the Lumia 650

Boot chain: Windows Boot Manager → `BootShim.efi` → `emmc_appsboot.mbn`
(Lumia650Pkg UEFI) → `\linux\zImage` (Linux EFI stub) + `\linux\saana.dtb`.

Windows stays the default and keeps working. Everything new is **added** to
the EFIESP partition; the only existing file that changes is the boot
configuration (`EFIESP\efi\Microsoft\Boot\BCD`), which is backed up first.
**Never touch any other partition**, especially `DPP` (factory provisioning data).

Requirements: a bootloader-unlocked phone (see [UNLOCK.md](../UNLOCK.md)),
a full eMMC backup, and a Windows PC with WPinternals.

## Files (`deploy/`, built locally, not in git)

| File | Goes to | From |
|---|---|---|
| `BootShim.efi` | `EFIESP\BootShim.efi` | imbushuo/boot-shim release `elf-loader-pre3` (ELF Variant 2.1) |
| `emmc_appsboot.mbn` | `EFIESP\emmc_appsboot.mbn` | `uefi/build.sh` |
| `linux/zImage` | `EFIESP\linux\zImage` | kernel build with `kernel/lumia650.config` |
| `linux/saana.dtb` | `EFIESP\linux\saana.dtb` | `kernel/dts/qcom-msm8909-microsoft-saana.dts` |

Check them with `SHA256SUMS` after copying them to the PC
(PowerShell: `Get-FileHash -Algorithm SHA256 <file>`).

## Phase 1: look, don't change (read-only)

1. WPinternals: **Phone → Manual mode → Mass Storage**. Wait for the phone's
   drives to appear in Windows.
2. Find EFIESP: it's either its own drive letter (a ~64 MB FAT volume) or the
   `EFIESP` folder inside the `MainOS` drive. Below, `E:\` means that location.
3. Admin PowerShell:
   ```
   $bcd = "E:\efi\Microsoft\Boot\BCD"
   bcdedit /store $bcd /enum all
   ```
4. Send the full output to Claude. The exact commands for phase 2 depend on
   the entries (GUIDs) on this phone.

## Phase 2: install (commands are finalised after phase 1)

1. Back up the BCD file: `Copy-Item $bcd "$HOME\Desktop\BCD.lumia650.bak"`.
2. Copy `BootShim.efi`, `emmc_appsboot.mbn` and the `linux` folder to `E:\`.
3. Add a new "Linux" boot entry (copied from an existing EFIESP app entry so
   the device is correct), point it at `\BootShim.efi`, turn on
   `nointegritychecks`, add it to the boot menu, and turn the menu on.
   Windows stays the default.

## Booting

Restart the phone. The Windows boot menu appears: **volume keys** move,
**power** selects. Choosing "Linux" runs BootShim (it prints a few lines),
then Lumia650Pkg (5 s countdown; press power for its menu), then Linux.

If anything hangs, hold **power** until the phone vibrates; it boots Windows
by default. To undo: restore the BCD backup and delete the added files.
