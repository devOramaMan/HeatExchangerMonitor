#!/bin/bash

# 1-Wire Bus Recovery Script
# Helps recover a stuck 1-Wire bus and clear phantom devices

# Function to completely reset 1-Wire system (cleanup + reinitialize)
reset_w1_system() {
    echo
    echo "=== 1-Wire System Reset ==="
    echo "This will remove and reload all 1-Wire kernel modules."
    read -p "Continue? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "🧹 Removing 1-Wire modules..."
        sudo modprobe -r w1_therm 2>/dev/null || true
        sudo modprobe -r w1_gpio 2>/dev/null || true
        sudo modprobe -r wire 2>/dev/null || true
        echo "   ✓ Modules removed"
        
        sleep 2
        
        echo "🚀 Reinitializing 1-Wire modules..."
        sudo modprobe w1_gpio
        if [[ $? -eq 0 ]]; then
            echo "   ✓ w1_gpio loaded"
        else
            echo "   ✗ Failed to load w1_gpio"
            return 1
        fi
        
        sudo modprobe w1_therm  
        if [[ $? -eq 0 ]]; then
            echo "   ✓ w1_therm loaded"
        else
            echo "   ✗ Failed to load w1_therm"
            return 1
        fi
        
        sleep 3  # Give time for bus master to initialize
        
        # Verify bus master is created
        if ls /sys/bus/w1/devices/w1_bus_master* >/dev/null 2>&1; then
            echo "   ✓ 1-Wire bus master initialized"
            
            # Trigger device search
            echo "🔍 Triggering device discovery..."
            if [[ -f /sys/bus/w1/devices/w1_bus_master1/w1_master_search ]]; then
                echo 1 | sudo tee /sys/bus/w1/devices/w1_bus_master1/w1_master_search >/dev/null 2>&1
                sleep 2
            fi
            
            # Show detected devices
            device_count=$(ls /sys/bus/w1/devices/28-* 2>/dev/null | wc -l)
            echo "   📊 Detected $device_count device device(s)"
            
            if [[ $device_count -gt 0 ]]; then
                ls /sys/bus/w1/devices/28-* 2>/dev/null | while read device; do
                    device_id=$(basename "$device")
                    echo "     Found: $device_id"
                done
            fi
            
            echo "✅ 1-Wire system reset complete!"
        else
            echo "   ✗ Bus master not found after reload"
            echo "   💡 This might indicate:"
            echo "      - Device tree overlay not loaded (check /boot/config.txt)"
            echo "      - Hardware connection issues"
            echo "      - GPIO pin conflicts"
            return 1
        fi
    else
        echo "Reset cancelled"
        return 1
    fi
}

# Optional: Cleanup only function (removes without reinitializing)
cleanup_w1_only() {
    echo
    echo "=== 1-Wire Cleanup Only ==="
    echo "⚠️  WARNING: This will remove modules without reinitializing!"
    echo "Use reset_w1_system() instead for complete reset with reinitialization."
    read -p "Continue with cleanup only? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Removing 1-Wire modules..."
        sudo modprobe -r w1_therm 2>/dev/null || true
        sudo modprobe -r w1_gpio 2>/dev/null || true
        sudo modprobe -r wire 2>/dev/null || true
        echo "✓ 1-Wire modules removed"
        echo "📝 Note: To reinitialize, run 'sudo modprobe w1_gpio && sudo modprobe w1_therm'"
        echo "📝 Note: To permanently disable, comment out 'dtoverlay=w1-gpio' in /boot/config.txt"
    else
        echo "Cleanup cancelled"
    fi
}



echo "=== 1-Wire Bus Recovery ==="
echo

# Function to reset 1-Wire bus
reset_w1_bus() {
    echo "🔄 Resetting 1-Wire bus..."
    
    # Stop any ongoing searches
    if [[ -f /sys/bus/w1/devices/w1_bus_master1/w1_master_search ]]; then
        echo "   Stopping bus search..."
        echo 0 | sudo tee /sys/bus/w1/devices/w1_bus_master1/w1_master_search >/dev/null 2>&1
        sleep 1
    fi
    
    # Remove phantom devices
    echo "   Removing phantom devices..."
    for device in /sys/bus/w1/devices/00-*; do
        if [[ -d "$device" ]]; then
            device_id=$(basename "$device")
            echo "     Removing phantom device: $device_id"
            echo "$device_id" | sudo tee /sys/bus/w1/devices/w1_bus_master1/w1_master_remove >/dev/null 2>&1
        fi
    done
    
    sleep 2
    
    # Restart bus search
    if [[ -f /sys/bus/w1/devices/w1_bus_master1/w1_master_search ]]; then
        echo "   Restarting bus search..."
        echo 1 | sudo tee /sys/bus/w1/devices/w1_bus_master1/w1_master_search >/dev/null 2>&1
    fi
    
    echo "   ✓ Bus reset complete"
}

# Function to reload kernel modules
reload_w1_modules() {
    echo "🔄 Reloading 1-Wire kernel modules..."
    
    # Remove modules
    sudo modprobe -r w1_therm 2>/dev/null
    sudo modprobe -r w1_gpio 2>/dev/null
    sleep 2
    
    # Reload modules
    sudo modprobe w1_gpio
    sudo modprobe w1_therm
    sleep 3
    
    echo "   ✓ Modules reloaded"
}

# Function to check bus health
check_bus_health() {
    echo "🔍 Checking bus health..."
    
    if [[ -d /sys/bus/w1/devices/w1_bus_master1 ]]; then
        echo "   ✓ Bus master active"
        
        # Check for phantom devices
        phantom_count=$(ls /sys/bus/w1/devices/00-* 2>/dev/null | wc -l)
        real_count=$(ls /sys/bus/w1/devices/28-* 2>/dev/null | wc -l)
        
        echo "   📊 Device count:"
        echo "     Real device devices: $real_count"
        echo "     Phantom devices: $phantom_count"
        
        if [[ $phantom_count -gt 0 ]]; then
            echo "   ⚠️  Phantom devices detected - bus may have issues"
            return 1
        else
            echo "   ✓ No phantom devices - bus appears healthy"
            return 0
        fi
    else
        echo "   ✗ Bus master not found"
        return 1
    fi
}

# Function to monitor bus activity
monitor_bus_activity() {
    echo "🔍 Monitoring bus activity for 10 seconds..."
    
    # Monitor dmesg for 1-Wire activity
    sudo dmesg -C  # Clear dmesg buffer
    sleep 10
    
    w1_activity=$(sudo dmesg | grep -i "w1\|onewire" | wc -l)
    if [[ $w1_activity -gt 0 ]]; then
        echo "   ✓ Bus activity detected ($w1_activity messages)"
        sudo dmesg | grep -i "w1\|onewire" | tail -5 | while IFS= read -r line; do
            echo "     $line"
        done
    else
        echo "   ⚠️  No bus activity detected"
    fi
}

# Main recovery process
echo "Starting 1-Wire bus recovery process..."
echo

# Step 1: Check initial state
check_bus_health
initial_health=$?

# Step 2: Try bus reset first
reset_w1_bus
sleep 3

# Step 3: Check if reset helped
check_bus_health
reset_health=$?

# Step 4: If still problematic, reload modules
if [[ $reset_health -ne 0 ]]; then
    echo
    echo "Bus reset didn't resolve issues, trying module reload..."
    reload_w1_modules
    sleep 3
    
    check_bus_health
    reload_health=$?
else
    reload_health=0
fi

# Step 4.5: Optional full system reset 
reset_w1_system

# Step 5: Monitor for activity
echo
monitor_bus_activity

# Step 6: Final recommendations
echo
echo "=== Recovery Summary ==="
if [[ $reload_health -eq 0 ]]; then
    echo "✅ Bus recovery successful!"
    echo "   The 1-Wire bus should now be sending reset signals normally."
else
    echo "❌ Bus recovery unsuccessful"
    echo "   🔧 Hardware troubleshooting needed:"
    echo "      1. Check device wiring (VDD, GND, Data)"
    echo "      2. Verify 4.7kΩ pull-up resistor between Data and VDD"
    echo "      3. Check power supply stability"
    echo "      4. Try different device sensor"
    echo "      5. Check for loose connections"
fi

echo
echo "To manually trigger a bus search:"
echo "  echo 1 | sudo tee /sys/bus/w1/devices/w1_bus_master1/w1_master_search"
echo
echo "To monitor ongoing activity:"
echo "  watch -n 1 'ls -la /sys/bus/w1/devices/'"