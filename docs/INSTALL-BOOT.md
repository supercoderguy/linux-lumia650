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
| `BootShim.efi` | `EFIESP\BootShim.efi` | sonic011gamer/boot-shim release `elf-loader-pre4` (copies the payload after ExitBootServices, so it can load at the stock UEFI's own 0x80200000; imbushuo's `elf-loader-pre3` refuses that address) |
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

## What phase 1 showed (RM-1152, OS 10.0.15254.603)

The phone's boot manager has no visible menu (`displaybootmenu No`,
`timeout 0`) and always goes through Mobile Startup (`bootsequence` with
`persistbootsequence Yes`), so a boot menu entry would be skipped. Before
that it checks two button actions (`processcustomactionsfirst Yes`):

| Hold at boot | BCD element on `{bootmgr}` | Starts |
|---|---|---|
| Volume up | `custom:54000001` | FFU Loader `{0ff5f24a-3785-4aeb-b8fe-4226215b88c4}` |
| Volume down | `custom:54000002` | Reset My Phone `{bd8951c4-eabd-4c6f-aafb-4ddb4eb0469b}` |

So Linux gets its own **copy** of the FFU Loader entry, and only the
volume-up action is pointed at it. The original FFU Loader entry is left as
it is, which makes undoing a single command.

## Phase 2: install

Admin PowerShell, phone still in mass storage, EFIESP on `P:` (adjust if not):

```
$bcd = "P:\efi\Microsoft\Boot\BCD"
$deploy = "$HOME\Desktop\lumia650-deploy"

# 1. Back up the boot configuration
Copy-Item $bcd "$HOME\Desktop\BCD.lumia650.bak"

# 2. Copy the files (adds new files only)
Copy-Item "$deploy\BootShim.efi", "$deploy\emmc_appsboot.mbn" P:\
Copy-Item "$deploy\linux" P:\linux -Recurse

# 3. New "Linux" entry, copied from the FFU Loader entry (same EFIESP device)
$out = bcdedit /store $bcd /copy '{0ff5f24a-3785-4aeb-b8fe-4226215b88c4}' /d "Linux (BootShim)"
$out
$linux = [regex]::Match("$out", '\{[0-9a-fA-F-]{36}\}').Value
$linux
bcdedit /store $bcd /set $linux path \BootShim.efi
bcdedit /store $bcd /set $linux nointegritychecks on
bcdedit /store $bcd /deletevalue $linux custom:26000201

# 4. Point the volume-up action at it
bcdedit /store $bcd /set '{bootmgr}' custom:54000001 $linux

# 5. Check
bcdedit /store $bcd /enum '{bootmgr}' /v
bcdedit /store $bcd /enum $linux /v
```

Expected: step 3 prints `The entry was successfully copied to {…}` and
`$linux` shows that GUID; the `{bootmgr}` listing shows `custom:54000001` =
that GUID; the new entry has `path \BootShim.efi` and `nointegritychecks Yes`.

Then give EFIESP's drive letter back (Windows only, nothing changes on the
phone) and restart the phone by holding power until it vibrates:

```
Get-Volume -FileSystemLabel EFIESP | Get-Partition | Remove-PartitionAccessPath -AccessPath P:\
```

## Booting

- **Normal start:** Windows, exactly as before.
- **Linux:** hold the power button until the phone vibrates, then immediately
  hold **volume up** until the Microsoft logo disappears. BootShim prints a few
  lines, Lumia650Pkg shows a 5 s countdown (power = its menu), then Linux starts.

If anything hangs, hold **power** until the phone vibrates; without volume up
it boots Windows.

## Undo

```
bcdedit /store $bcd /set '{bootmgr}' custom:54000001 '{0ff5f24a-3785-4aeb-b8fe-4226215b88c4}'
```

Optionally also `bcdedit /store $bcd /delete <Linux GUID>` and delete
`P:\BootShim.efi`, `P:\emmc_appsboot.mbn` and `P:\linux`. Or copy the BCD
backup back over `P:\efi\Microsoft\Boot\BCD`.
