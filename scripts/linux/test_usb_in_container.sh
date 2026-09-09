#!/bin/bash
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb ubuntu:22.04 bash -c '
echo "===DEV NODES==="
ls -la /dev/bus/usb/001/ 2>&1
echo "===DEVICE LIST==="
for d in /sys/bus/usb/devices/*/; do
  if [ -f "$d/idVendor" ]; then
    VID=$(cat "$d/idVendor" 2>/dev/null)
    PID=$(cat "$d/idProduct" 2>/dev/null)
    echo "$VID:$PID"
  fi
done | sort | uniq -c
echo "===CONTAINER_TEST_DONE==="
' 2>&1
