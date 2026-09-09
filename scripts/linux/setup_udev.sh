#!/bin/bash
# Create Odin1 udev rule per official manifoldsdk/odin_ros_driver README
set -e
RULE_FILE=/etc/udev/rules.d/99-odin-usb.rules
cat > "$RULE_FILE" <<'EOF'
# Odin1 (Manifold Tech) - USB access for ROS driver / libusb
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="0019", MODE="0666", GROUP="plugdev"
EOF
echo "===RULE WRITTEN==="
cat "$RULE_FILE"
udevadm control --reload-rules
udevadm trigger
echo "===RELOADED==="
# ensure root is in plugdev (harmless, matches official doc)
id root
echo "===DEV NODE AFTER==="
ls -la /dev/bus/usb/001/ 2>/dev/null
echo "DONE"
