#!/bin/bash
# save_map.sh - Ask the SLAM device to save the current map, then copy to a scene_<timestamp> name
# Usage: ./scripts/ros/save_map.sh [scene_name]
set -e
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
MAPS="$REPO/data/maps"
STAMP="$(date +%Y%m%d_%H%M%S)"
SCENE="${1:-scene_$STAMP}"

mkdir -p "$MAPS"

echo "=== Sending save_map command to driver ==="
docker exec odin_ros bash -c 'echo "set save_map 1" > /tmp/odin_command.txt; echo SENT'

echo "=== Waiting for device map generation + transfer (up to 30s) ==="
for i in $(seq 1 30); do
  NEW=$(find "$MAPS" -name "map_*.bin" -newer "$MAPS/.gitkeep" 2>/dev/null | sort | tail -1)
  if [ -n "$NEW" ]; then break; fi
  sleep 1
done

if [ -z "$NEW" ]; then
  echo "[-] No new map file found in $MAPS" >&2
  exit 1
fi

# wait for transfer to finish (file size stable)
sleep 3
cp "$NEW" "$MAPS/$SCENE.bin"
ls -la "$MAPS/$SCENE.bin"
echo "[+] Map saved: $MAPS/$SCENE.bin ($(stat -c%s "$MAPS/$SCENE.bin") bytes, md5 $(md5sum "$MAPS/$SCENE.bin" | cut -d' ' -f1))"
echo "[i] Original: $NEW"
