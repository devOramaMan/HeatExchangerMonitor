#!/bin/bash

# 1-Wire System Diagnostic Script
# Helps diagnose 1-Wire setup 

echo "=== 1-Wire System Diagnostic ==="
echo

# Check if running 
if [[ ! -f /proc/cpuinfo ]] || ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi"
fi

echo "1. Checking 1-Wire kernel modules:"
echo "   w1-gpio module:"
if lsmod | grep -q "w1_gpio"; then
    echo "   ✓ w1-gpio is loaded"
else
    echo "   ✗ w1-gpio is NOT loaded"
    echo "     Load with: sudo modprobe w1-gpio"
fi

echo "   w1-therm module:"
if lsmod | grep -q "w1_therm"; then
    echo "   ✓ w1-therm is loaded"
else
    echo "   ✗ w1-therm is NOT loaded"
    echo "     Load with: sudo modprobe w1-therm"
fi

echo

echo "2. Checking 1-Wire bus interface:"
if [[ -d /sys/bus/w1 ]]; then
    echo "   ✓ 1-Wire bus interface exists"
    
    echo "   1-Wire masters:"
    if ls /sys/bus/w1/devices/w1_bus_master* 2>/dev/null; then
        for master in /sys/bus/w1/devices/w1_bus_master*; do
            if [[ -d "$master" ]]; then
                echo "     Found: $(basename "$master")"
            fi
        done
    else
        echo "     ✗ No 1-Wire masters found"
    fi
    
    echo "   All 1-Wire devices:"
    device_found=false
    for device in /sys/bus/w1/devices/*-*; do
        if [[ -d "$device" ]]; then
            device_found=true
            device_id=$(basename "$device")
            family_code=${device_id:0:2}
            
            # Identify device type by family code
            case "$family_code" in
                "28")
                    device_type="DS18B20 Temperature Sensor"
                    ;;
                "10")
                    device_type="DS18S20 Temperature Sensor"
                    ;;
                "22")
                    device_type="DS1822 Temperature Sensor"
                    ;;
                "00")
                    device_type="Unknown/Phantom Device (possible wiring issue)"
                    ;;
                *)
                    device_type="Unknown Device (Family: 0x$family_code)"
                    ;;
            esac
            
            echo "     Found: $device_id ($device_type)"
            
            # Try to read temperature for temperature sensors
            if [[ "$family_code" == "28" || "$family_code" == "10" || "$family_code" == "22" ]]; then
                if [[ -f "$device/w1_slave" ]]; then
                    temp_data=$(cat "$device/w1_slave" 2>/dev/null)
                    if [[ $? -eq 0 ]]; then
                        if echo "$temp_data" | grep -q "YES"; then
                            temp_raw=$(echo "$temp_data" | grep -o "t=[0-9-]*" | cut -d= -f2)
                            if [[ -n "$temp_raw" ]]; then
                                temp_celsius=$(echo "scale=3; $temp_raw / 1000" | bc -l 2>/dev/null || echo "calc_error")
                                echo "       Temperature: ${temp_celsius}°C"
                            fi
                        else
                            echo "       ⚠️  CRC check failed - device may be unreliable"
                        fi
                    else
                        echo "       ✗ Cannot read temperature data"
                    fi
                else
                    echo "       ✗ No w1_slave interface found"
                fi
            elif [[ "$family_code" == "00" ]]; then
                echo "       ⚠️  This may indicate:"
                echo "          - Bus noise or interference"
                echo "          - Wiring problems (loose connections)"
                echo "          - Power supply issues"
                echo "          - Missing pull-up resistor"
            fi
        fi
    done
    
    if [[ "$device_found" == false ]]; then
        echo "     ✗ No 1-Wire devices found"
        echo "       Check connections and pull-up resistor (4.7kΩ)"
    fi
else
    echo "   ✗ 1-Wire bus interface does not exist"
    echo "     Kernel modules may not be loaded"
fi

echo

echo "3. Detecting actual 1-Wire GPIO pin:"
# Check multiple sources to determine which GPIO pin is used for 1-Wire
w1_gpio_pin=""

# Method 1: Check loaded device tree overlays
echo "   Checking loaded overlays:"
if command -v dtoverlay >/dev/null 2>&1; then
    overlay_info=$(sudo dtoverlay -l 2>/dev/null | grep w1-gpio)
    if [[ -n "$overlay_info" ]]; then
        echo "   ✓ Device tree overlay loaded: $overlay_info"
        # Extract GPIO pin if specified
        if echo "$overlay_info" | grep -q "gpiopin="; then
            w1_gpio_pin=$(echo "$overlay_info" | grep -o "gpiopin=[0-9]*" | cut -d= -f2)
        else
            w1_gpio_pin="4"  # Default
        fi
    else
        echo "   ✗ No w1-gpio overlay loaded"
    fi
else
    echo "   ⚠️  dtoverlay command not available"
fi

# Method 2: Check kernel messages
echo "   Checking kernel messages:"
w1_dmesg=$(sudo dmesg 2>/dev/null | grep -i "w1-gpio.*gpio pin" | tail -1)
if [[ -n "$w1_dmesg" ]]; then
    echo "   ✓ Kernel message found: $w1_dmesg"
    # Extract GPIO pin number from dmesg
    dmesg_pin=$(echo "$w1_dmesg" | grep -o "gpio pin [0-9]*" | grep -o "[0-9]*")
    if [[ -n "$dmesg_pin" ]]; then
        w1_gpio_pin="$dmesg_pin"
    fi
else
    echo "   ✗ No w1-gpio kernel messages found"
fi

# Method 3: Check device tree runtime
echo "   Checking device tree runtime:"
if [[ -d /proc/device-tree ]]; then
    if ls /proc/device-tree/onewire* 2>/dev/null >/dev/null; then
        echo "   ✓ 1-Wire device tree node found"
        # Try to read GPIO configuration
        for onewire_node in /proc/device-tree/onewire*; do
            if [[ -f "$onewire_node/gpios" ]]; then
                echo "     Found GPIO configuration in $onewire_node"
            fi
        done
    else
        echo "   ✗ No 1-Wire device tree nodes found"
    fi
else
    echo "   ⚠️  Device tree not accessible"
fi

# Method 4: Check GPIO debug interface
echo "   Checking GPIO debug interface:"
if [[ -r /sys/kernel/debug/gpio ]]; then
    echo "   ✓ GPIO debug interface accessible"
    # Look for GPIO pins claimed by w1-gpio
    w1_gpio_debug=$(sudo cat /sys/kernel/debug/gpio 2>/dev/null | grep -i "w1-gpio\|onewire")
    if [[ -n "$w1_gpio_debug" ]]; then
        echo "   ✓ Found 1-Wire GPIO assignment:"
        echo "$w1_gpio_debug" | while IFS= read -r line; do
            echo "     $line"
        done
        # Extract GPIO pin number from debug output
        debug_pin=$(echo "$w1_gpio_debug" | grep -o "gpio-[0-9]*" | grep -o "[0-9]*" | head -1)
        if [[ -n "$debug_pin" ]]; then
            w1_gpio_pin="$debug_pin"
            echo "   🎯 Detected GPIO pin from debug interface: $debug_pin"
        fi
    else
        echo "   ✗ No 1-Wire GPIO assignments found in debug interface"
    fi
else
    echo "   ⚠️  GPIO debug interface not accessible (requires root)"
    echo "     Try: sudo cat /sys/kernel/debug/gpio | grep -i w1"
fi

# Summary of GPIO detection
echo "   1-Wire GPIO pin detection summary:"
if [[ -n "$w1_gpio_pin" ]]; then
    echo "   🎯 1-Wire is configured on GPIO pin: $w1_gpio_pin"
    
    # Verify this pin is actually busy
    if command -v gpioget >/dev/null 2>&1; then
        if ! gpioget gpiochip0 $w1_gpio_pin >/dev/null 2>&1; then
            echo "   ✓ Confirmed: GPIO $w1_gpio_pin is busy (consistent with 1-Wire usage)"
        else
            echo "   ⚠️  GPIO $w1_gpio_pin appears available (1-Wire may not be active)"
        fi
    fi
else
    echo "   ❓ Cannot determine which GPIO pin is used for 1-Wire"
    if [[ ${#busy_pins[@]} -gt 0 ]]; then
        echo "   🔍 Busy GPIO pins that could be 1-Wire: ${busy_pins[*]}"
    fi
fi

echo

echo "4. Checking libgpiod availability:"
if command -v gpiodetect >/dev/null 2>&1; then
    echo "   ✓ libgpiod tools available"
    echo "   GPIO chips:"
    gpiodetect 2>/dev/null | while read line; do
        echo "     $line"
    done
else
    echo "   ✗ libgpiod tools not found"
    echo "     Install with: sudo apt install gpiod"
fi

echo

echo "5. Checking device tree configuration:"
if [[ -f /boot/config.txt ]]; then
    echo "   Checking /boot/config.txt for 1-Wire settings:"
    if grep -q "dtoverlay=w1-gpio" /boot/config.txt 2>/dev/null; then
        echo "   ✓ w1-gpio device tree overlay is configured"
        gpio_pin=$(grep "dtoverlay=w1-gpio" /boot/config.txt | grep -o "gpiopin=[0-9]*" | cut -d= -f2)
        if [[ -n "$gpio_pin" ]]; then
            echo "     GPIO pin: $gpio_pin"
        else
            echo "     GPIO pin: 4 (default)"
        fi
    else
        echo "   ✗ w1-gpio device tree overlay not found"
        echo "     Add to /boot/config.txt: dtoverlay=w1-gpio,gpiopin=4"
    fi
else
    echo "   ⚠️  /boot/config.txt not found (different boot configuration?)"
fi

echo

echo "6. Recommendations:"
echo "   For kernel-based 1-Wire (recommended):"
echo "   - Ensure 'dtoverlay=w1-gpio,gpiopin=4' is in /boot/config.txt"
echo "   - Reboot after adding device tree overlay"
echo "   - Load modules: sudo modprobe w1-gpio && sudo modprobe w1-therm"
echo "   - Connect DS18B20 with 4.7kΩ pull-up resistor"
echo
echo "   For direct GPIO control:"
echo "   - Remove 1-Wire kernel modules: sudo modprobe -r w1-therm w1-gpio"
echo "   - Use libgpiod-based HAL with available GPIO pins"
echo

echo "=== Diagnostic Complete ==="