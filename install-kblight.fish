#!/usr/bin/env fish
# install-kblight.fish
# Full local installer for Gigabyte G5 MF5 keyboard backlight on Void Linux
# Run once: sudo fish install-kblight.fish

set SCRIPT_DIR (realpath (dirname (status filename)))
set DRIVER_DIR "$SCRIPT_DIR/clevo-keyboard"

# ── 1. Check root ────────────────────────────────────────────────────────────
if test (id -u) -ne 0
    echo "Run as root: sudo fish install-kblight.fish"
    exit 1
end

# ── 2. Verify local driver source exists ─────────────────────────────────────
if not test -d $DRIVER_DIR
    echo "ERROR: Local 'clevo-keyboard' folder not found inside this repository!"
    echo "Please ensure you copied the driver folder to: $DRIVER_DIR"
    exit 1
end

# ── 3. Install build deps (Adding DKMS for kernel update survival) ───────────
echo "==> Installing build dependencies..."
xbps-install -Sy git make gcc linux-headers dkms

# ── 4. Build & Install via DKMS ──────────────────────────────────────────────
echo "==> Registering and building driver modules via DKMS..."
cd $DRIVER_DIR
make clean

# Leverage the repository's native DKMS installer
make dkmsinstall
if test $status -ne 0
    echo "ERROR: DKMS installation failed."
    exit 1
end
echo "    DKMS installation complete! Modules will auto-rebuild on kernel updates."

# ── 5. modules-load.d (Ensures persistence across reboots) ───────────────────
echo "==> Writing /etc/modules-load.d/tuxedo.conf..."
echo "led_class_multicolor
clevo_acpi
clevo_wmi
tuxedo_keyboard" > /etc/modules-load.d/tuxedo.conf

# ── 6. Install kblight script ────────────────────────────────────────────────
echo "==> Installing kblight control script..."
set SCRIPT_DEST /usr/local/bin/kblight
cp $SCRIPT_DIR/kblight.fish $SCRIPT_DEST
chmod +x $SCRIPT_DEST
echo "    Installed CLI utility to $SCRIPT_DEST"

# ── 7. Load modules cleanly (Live activation using the system modules) ──────
echo "==> Loading modules into the current session..."
modprobe led_class_multicolor
modprobe clevo_acpi
modprobe clevo_wmi
modprobe tuxedo_keyboard

# ── 8. Verify ────────────────────────────────────────────────────────────────
if test -d /sys/class/leds/rgb:kbd_backlight
    echo ""
    echo "✓ Success! Keyboard backlight interface found."
    echo "  Try: kblight status"
    echo "  Try: sudo kblight color 255 0 0"
else
    echo ""
    echo "WARNING: LED interface not found after loading modules."
    echo "Check hardware system logs: sudo dmesg | tail -20"
end

echo ""
echo "==> Done! Everything is self-contained and will persist across restarts."

# ── 9. Install Background Daemon (runit) ─────────────────────────────────────
echo "==> Setting up kblightd background service..."
cp $SCRIPT_DIR/kblight-effects.py /usr/local/bin/kblightd
chmod +x /usr/local/bin/kblightd

mkdir -p /etc/sv/kblightd
echo '#!/bin/sh
exec 2>&1
exec /usr/local/bin/kblightd' > /etc/sv/kblightd/run
chmod +x /etc/sv/kblightd/run

# Enable the service if it isn't already
if not test -L /var/service/kblightd
    ln -s /etc/sv/kblightd /var/service/
    echo "    Service enabled and started!"
else
    sv restart kblightd
    echo "    Service restarted!"
end