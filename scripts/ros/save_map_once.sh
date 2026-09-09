#!/bin/bash
set -e
cd /root/projects/Odin1-Scene-Reconstruction
mkdir -p data/maps

echo "=== SEND save_map COMMAND ==="
docker exec odin_ros bash -c 'echo "set save_map 1" > /tmp/odin_command.txt; echo SENT'
echo "=== WAIT 20s ==="
sleep 20
echo "=== MAPS DIR ==="
ls -la data/maps/ 2>/dev/null
echo "=== DRIVER LOG (save_map related) ==="
grep -iE "save_map|map" /root/projects/Odin1-Scene-Reconstruction/logs/driver_core.log | tail -8
