#!/usr/bin/env python3
import time
import sys
import colorsys
import os
import select

# Target sysfs paths
INTENSITY_PATH = "/sys/class/leds/rgb:kbd_backlight/multi_intensity"
BRIGHTNESS_PATH = "/sys/class/leds/rgb:kbd_backlight/brightness"

# --- Configuration ---
IDLE_TIMEOUT_SEC = 15.0  # Seconds of inactivity before lights shut off
SWEEP_SPEED = 0.01       # Lower = slower, smoother color transition

def find_internal_keyboard():
    """Scans the kernel input registry to find the laptop's physical keyboard device file."""
    try:
        with open("/proc/bus/input/devices", "r") as f:
            blocks = f.read().split("\n\n")
            for block in blocks:
                # 'AT Translated Set 2' is the universal identifier for internal x86 laptop keyboards
                if "AT Translated Set 2 keyboard" in block or "Clevo" in block:
                    for line in block.split("\n"):
                        if line.startswith("H: Handlers="):
                            for token in line.split():
                                if token.startswith("event"):
                                    return f"/dev/input/{token}"
    except Exception as e:
        print(f"Error reading input devices: {e}")
    return None

def gradient_sweep():
    kbd_dev = find_internal_keyboard()
    if not kbd_dev:
        print("Warning: Could not detect internal keyboard. Idle sleep is disabled.")
        fd = None
    else:
        print(f"==> Detected internal keyboard at: {kbd_dev}")
        # Open the raw keyboard device file in non-blocking mode
        fd = os.open(kbd_dev, os.O_RDONLY | os.O_NONBLOCK)

    print(f"==> Smooth Gradient active. Idle timeout: {IDLE_TIMEOUT_SEC}s. Press Ctrl+C to stop.")
    
    try:
        with open(BRIGHTNESS_PATH, "w") as f:
            f.write("255\n")
    except IOError:
        print("Error: Cannot write to LED sysfs interface. Did you forget sudo?")
        sys.exit(1)

    start_time = time.time()
    last_active = time.time()
    is_sleeping = False

    try:
        while True:
            # 1. Listen for raw hardware keystrokes (timeout of 0.02s acts as our 50 FPS framerate)
            if fd is not None:
                ready, _, _ = select.select([fd], [], [], 0.02)
                if ready:
                    # Flush the kernel event buffer so it doesn't get stuck
                    os.read(fd, 1024)
                    last_active = time.time()
                    
                    # Wake up instantly on keypress
                    if is_sleeping:
                        is_sleeping = False
                        with open(BRIGHTNESS_PATH, "w") as f:
                            f.write("255\n")
            else:
                time.sleep(0.02) # Fallback sleep if keyboard monitoring failed

            # 2. Check for inactivity
            if not is_sleeping and (time.time() - last_active > IDLE_TIMEOUT_SEC):
                is_sleeping = True
                with open(BRIGHTNESS_PATH, "w") as f:
                    f.write("0\n")

            # 3. Calculate and push colors (only process math if lights are actually on)
            if not is_sleeping:
                elapsed = time.time() - start_time
                
                # Rotate the hue wheel slowly over time
                hue = (elapsed * SWEEP_SPEED) % 1.0
                
                # Value (brightness) and Saturation are pinned to 1.0 for a pure color sweep
                r_f, g_f, b_f = colorsys.hsv_to_rgb(hue, 1.0, 1.0)
                
                r_int = int(r_f * 255)
                g_int = int(g_f * 255)
                b_int = int(b_f * 255)
                
                with open(INTENSITY_PATH, "w") as f:
                    f.write(f"{r_int} {g_int} {b_int}\n")
                    
    except KeyboardInterrupt:
        # User requested exit: gracefully power down the lights entirely
        with open(BRIGHTNESS_PATH, "w") as f:
            f.write("0\n")
        print("\n==> Engine stopped. Keyboard lights turned off.")
        
    finally:
        if fd is not None:
            os.close(fd)

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Error: This effect daemon requires root privileges to talk to /sys and /dev/input.")
        sys.exit(1)
        
    gradient_sweep()