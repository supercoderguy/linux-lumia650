# Unlocking the Lumia 650 (RM-1152) bootloader with WPinternals

Machine: Surface Laptop Go 3 (Windows 11). Based on reading WPinternals' source
(github.com/ReneLergner/WPinternals, latest commit 2026-04-22).

Your phone uses the newer "Spec B" bootloader, so WPinternals uses its
"SecureBoot Unlock V2" method.

## 0. Before you start

- Phone charged above 50%. Laptop on its charger, with sleep turned off.
- Back up anything on the phone you care about.
- Phone: Settings → System → About → note the **OS build**. WPinternals has
  boot patches for builds up to 10.0.15254.603, which is the final release. If
  your build is older than 10.0.15254.527, stop and report the exact number.
- Laptop: not in S mode (Settings → System → Activation).
- Use a good data USB cable plugged directly into the laptop, not through a hub
  or dock.

## 1. Install WPinternals (on the Surface)

1. Download the latest release from
   https://github.com/ReneLergner/WPinternals/releases and extract it.
2. Run `WPinternals.exe`. If Windows asks for the .NET 8 Desktop Runtime,
   install it. If SmartScreen blocks it: "More info → Run anyway".
3. Accept the disclaimer and let it install its drivers.

## 2. Connect and identify

1. Boot the phone normally into Windows, unlock its screen, and plug it in.
2. In WPinternals: **Phone → Info**. Check that it shows **RM-1152** and
   write down the bootloader/security status it reports.

## 3. Download your recovery kit

Current WPinternals has **no online search**. Microsoft's firmware servers are
gone, and the Download page only adds files you already have. Get the files from
the Internet Archive's `W10M_FFUs` collection (https://archive.org/details/W10M_FFUs):

| File | Path in the collection | Size | MD5 |
|---|---|---|---|
| FFU | `Microsoft/Lumia 650 (RM-1152)/VAR EURO 1X CV/RM1152_1078.0042.10586.13333.15508.0352E9_retail_prod_signed.ffu` | 2.0 GB | `09d933acd786ce162a8c00b39095730b` |
| Emergency programmer (EDE) | `Emergency Files/RM-1152/Manufacturing SW Package/MPRG8909_fh.ede` | 143 KB | `82d975524a8d89e82a4ed1d7080692fd` |
| Emergency payload (EDP) | `Emergency Files/RM-1152/Manufacturing SW Package/RM1152_fh.edp` | 3.4 MB | `ed7b6808943b002f632c90dac0c74059` |

1. Download all three and check the MD5s
   (PowerShell: `Get-FileHash -Algorithm MD5 <file>`).
2. In WPinternals: **Platform → Download → "Add existing FFU-file..."** → pick
   the FFU.
3. Copy all of it to a second place, such as the Arch machine or a USB stick.
   This is your way back if something breaks.

The FFU is the European single-SIM version ("EURO 1X CV"). That's fine for
profiling because the hardware is the same as yours. If WPinternals says the
FFU's OS version isn't supported, it will ask for a "donor FFU". Report that
before picking one.

## 4. Unlock

1. **Unlock → Unlock bootloader**.
2. It will say the phone needs to switch to Flash mode. Continue.
3. On the resources screen ("SecureBoot Unlock V2"):
   - *Select your FFU-image for profiling* → the RM-1152 FFU from step 3.
   - *Select the EDE-file for your phone* → the emergency programmer from step 3.
   - If it complains that the FFU's OS version isn't supported, stop and
     report it. Don't pick a random donor FFU.
4. Click **Unlock**.

### What to expect (this is normal)

- The phone reboots **many times** while WPinternals looks for a "Flashing
  Profile". It will also enter **Emergency Download Mode**, where the screen
  stays black. This can take a while.
- **Don't unplug the phone and don't close WPinternals** while it's working.
- If the phone obviously hangs (black screen, nothing happening for a few
  minutes, and WPinternals isn't making progress), hold the power button until
  the phone vibrates. WPinternals' own docs say to do exactly this.
- If it fails halfway with a "boot order" problem, WPinternals rolls the
  changes back. Reboot the phone normally, let it fully start Windows, then try
  again.

## 5. Check the result

1. The phone should boot back into Windows.
2. **Phone → Info** should now show the bootloader as unlocked.
3. If the phone doesn't boot properly: don't panic and don't keep retrying.
   Mass Storage mode should still work. Save the log and report back.

## 6. Back up the original partitions (important for the Linux port)

1. **Phone → Manual mode → Mass Storage**.
2. Back up the whole eMMC (the phone's internal storage). The easiest way is to
   plug the phone into the Arch machine, run `lsblk`, and paste the output to
   Claude for the exact `dd` command. Don't guess the device name, because
   writing to the wrong disk destroys data.
3. At minimum, keep copies of **EFIESP**, **UEFI** and **SBL1**.

## If something goes wrong

- Save the WPinternals log.
- Note what the phone screen shows (black, Windows logo, gears, lightning bolt,
  "NOKIA"/"Microsoft" logo, etc.).
- Report back before trying anything else.

Notes:
- While the bootloader is unlocked, Windows can't install updates on the phone.
- **Unlock → Restore bootloader** undoes the unlock.
