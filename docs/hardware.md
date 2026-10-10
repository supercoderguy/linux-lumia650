# Lumia 650 (RM-1152) hardware map

Derived from the phone's own ACPI tables (PLAT partition, `dsdt.aml`/`ssdt.aml`,
OEM ID `QCOMM MSM8909`), decompiled with `iasl -d`. The tables themselves are
Microsoft's and aren't in this repo; regenerate them from your own eMMC dump.

"TLMM" GPIOs are the MSM8909's own pins (`&tlmm N` in Linux). "PM01" pins
belong to the PM8909 power chip; Windows numbers its power-on keys as 64/65.

| Function | ACPI device / HID | Bus, address | GPIOs | Linux node (msm8909.dtsi) |
|---|---|---|---|---|
| Touchscreen | `TSC1` / `MSHW1003` | I2C5 @ `0x4b` | IRQ TLMM 13 (falling, pull-up), reset TLMM 12 | `&blsp_i2c5`, likely `syna,rmi4-i2c` like the 8x26 Lumias |
| Accelerometer | `ACC1`/`ACC2` / `MSHW101A`/`MSHW101B` | I2C1 @ `0x1e` | IRQ TLMM 96 (level high) | `&blsp_i2c1` |
| Light/proximity | `APS1` / `MSHW1016` | I2C1 @ `0x39` | IRQ TLMM 94 (falling) | `&blsp_i2c1` |
| NFC | `NFC1` / `PN547` | I2C2 @ `0x28` | IRQ TLMM 21, enable TLMM 20, firmware TLMM 22 | `&blsp_i2c2`, `nxp,pn544-i2c` family |
| Display | `DISP` / `MSHW1004` | MDSS DSI | TE TLMM 24, reset TLMM 25 | panel driver TBD; start with `simple-framebuffer` |
| microSD | `SDC2` / `QCOM2466` | `0x07864900` | card detect TLMM 38 | `&sdhc_2` |
| Power key | `BTNS` / `ACPI0011` | PM8909 PON | PM01 64 | `pm8909_pwrkey` |
| Volume down | `BTNS` | PM8909 PON (RESIN) | PM01 65 | `pm8909_resin` |
| Volume up | `BTNS` | — | TLMM 90 (pull-up) | `gpio-keys` |
| Debug UART | `UAR1` / `QCOM2424` | `0x078af000` | — | `&blsp_uart1` |
| Camera power | `CAMP` / `QCOM0775` | — | TLMM 31–34, 97, 99 | later |

I2C bus mapping: ACPI `I2C1` = `0x078b5000` = `&blsp_i2c1`, `I2C2` =
`0x078b6000` = `&blsp_i2c2`, `I2C5` = `0x078b9000` = `&blsp_i2c5`.

Not yet confirmed: the exact touch and sensor chip models (the HIDs are
Microsoft-generic), the display panel model, and the regulator for each device.

## PM8909 power rails (from the ACPI power-management tables)

Voltages the Windows firmware requests per device. **These differ from the
generic MSM8909 values used by other boards**, and forcing the generic ones
froze the phone (S2 especially).

| Rail | Lumia voltage | Used by (ACPI device) | Generic msm8909 value |
|---|---|---|---|
| S2 | **1.95 V** | display, touch, accelerometer, audio; feeds the 1.8 V LDOs | 1.85 V |
| L2 | 1.2–1.225 V | USB, cameras | 1.2 V |
| L5 | 1.8 V | eMMC VCCQ (SDC1), NFC, audio, WCN | 1.8 V |
| L6 | 1.8 V | display, touch, sensors, cameras (I/O) | 1.8 V |
| L7 | 1.8 V | WCN, USB PHY | 1.8 V |
| L8 | 2.85–2.9 V | eMMC VCC (SDC1) | 2.85–2.9 V |
| L9 | **3.3 V** | WCN (RIVA) | 3.0–3.3 V |
| L10 | **1.3 V** | WCN (RIVA) | 1.225–1.3 V |
| L11 | 2.95 V | microSD VCC | 1.8–2.95 V |
| L12 | 1.85 / 2.95 V | microSD VCCQ | 1.8–2.95 V |
| L13 | 3.075 V | USB PHY, audio | 3.075 V |
| L17 | 2.85 V | touch, light sensor, cameras | 2.85 V |
| L21 | 2.95 V | unknown (not in the Linux PM8909 driver) | — |

L1, L3, L4, L14, L15, L18–L20 and S1 appear without a voltage (CPU/system
rails managed by the firmware).
