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
