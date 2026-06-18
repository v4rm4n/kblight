# kblight (Gigabyte G5 MF5 Keyboard Backlight Control)

A lightweight, self-contained setup to manage the RGB keyboard backlight on a Gigabyte G5 MF5 laptop running **Void Linux**. 

This repository patches the hardware gap by vendoring the Clevo/Tuxedo kernel drivers, using DKMS to ensure they survive rolling-release kernel updates, and providing a clean Fish shell CLI utility to adjust brightness and colors.

# Tried and tested!

![kblight_test](./kblight_test.gif)

## Repository Structure

```text
kblight/
├── clevo-keyboard/       # Cleaned-up driver source code
│   ├── src/
│   ├── dkms.conf
│   └── Makefile
├── install-kblight.fish  # Automated setup script
├── kblight.fish          # Backlight CLI script
└── README.md             # This file
```

# Installation

Run the automated installer script using `sudo`. The script will pull down system build dependencies via `xbps-install`, compile and register the kernel modules via DKMS, configure them to load at boot, and install the `kblight` utility to your global path.

```bash
git clone https://github.com/v4rm4n/kgblight.git
cd kblight
sudo fish install-kblight.fish
```

# Why this method is bulletproof for Void Linux

- **DKMS Integration:** Void is a rolling distro. Whenever `xbps-install` updates your Linux kernel, DKMS triggers behind the scenes to rebuild these keyboard modules automatically. You don't have to re-compile things manually.

- **Persistence:** The installer registers the modules under `/etc/modules-load.d/tuxedo.conf` so your keyboard lighting interface is ready to use immediately on system boot.


# Usage

Once installed, you can call the kblight utility from anywhere in your terminal.

    ⚠️ Note: Turning the light `on`, `off`, or changing the `color` interacts with system files under `/sys/` and requires `sudo`. Checking the `status` does not require root privileges.

## 1. Check Current Status

See your current backlight brightness caps, values, and active RGB settings.

```
kblight status
```

## 2. Turn the Backlight On

Turns the lights on. Defaults to maximum brightness (255) if no value is passed.

```bash
sudo kblight on
# Or specify custom brightness (0-255)
sudo kblight on 128
```

## 3. Change Backlight Color

Set custom RGB color profiles. You can optionally specify a custom brightness level as the 4th argument.

```bash
# Set to solid Red
sudo kblight color 255 0 0

# Set to solid Blue at half brightness
sudo kblight color 0 0 255 128

# Set to solid Purple at max brightness
sudo kblight color 128 0 128 255
```

## 4. Turn the Backlight Off

Completely shuts down the keyboard LEDs.

```bash
sudo kblight off
```

# Service management

```bash
# Check the status (and uptime):
sudo sv status kblightd

# Turn off the effects temporarily:
sudo sv down kblightd

# Turn the effects back on:
sudo sv up kblightd

# Restart it (if you modify the python script later):
sudo sv restart kblightd
```