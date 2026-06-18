#!/usr/bin/env fish
# kblight - Keyboard backlight control for Gigabyte G5 MF5
# Usage:
#   kblight off
#   kblight on [brightness]
#   kblight color <R> <G> <B> [brightness]
#   kblight status

set LED /sys/class/leds/rgb:kbd_backlight

function usage
    echo "Usage:"
    echo "  kblight off"
    echo "  kblight on [brightness 0-255, default 255]"
    echo "  kblight color <R> <G> <B> [brightness 0-255, default 255]"
    echo "  kblight status"
    exit 1
end

function check_led
    if not test -d $LED
        echo "Error: LED interface not found. Are the modules loaded?"
        echo "Run: sudo modprobe led_class_multicolor && sudo insmod /path/to/tuxedo_keyboard.ko"
        exit 1
    end
end

function require_root
    if test (id -u) -ne 0
        echo "Error: requires root (use sudo)"
        exit 1
    end
end

switch $argv[1]
    case off
        check_led
        require_root
        echo 0 > $LED/brightness
        echo "Keyboard backlight off."

    case on
        check_led
        require_root
        set brightness 255
        if test (count $argv) -ge 2
            set brightness $argv[2]
        end
        echo $brightness > $LED/brightness
        echo "Keyboard backlight on (brightness: $brightness)."

    case color
        check_led
        require_root
        if test (count $argv) -lt 4
            usage
        end
        set r $argv[2]
        set g $argv[3]
        set b $argv[4]
        set brightness 255
        if test (count $argv) -ge 5
            set brightness $argv[5]
        end
        echo "$r $g $b" > $LED/multi_intensity
        echo $brightness > $LED/brightness
        echo "Color set to R=$r G=$g B=$b (brightness: $brightness)."

    case status
        check_led
        set brightness (cat $LED/brightness)
        set intensity (cat $LED/multi_intensity)
        set max (cat $LED/max_brightness)
        echo "Brightness: $brightness / $max"
        echo "Color (R G B): $intensity"
        if test $brightness -eq 0
            echo "State: OFF"
        else
            echo "State: ON"
        end

    case '*'
        usage
end
