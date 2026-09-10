# Odin1 firmware update incident report - 2026-09-10

## Executive summary

An Odin1 that had previously streamed through Windows 11 -> usbipd -> WSL2 -> Docker -> ROS 2 became unavailable at the USB-enumeration layer during an official firmware update. The update used the vendor's Odin1 v0.14.1 package and its x86_64 v0.5.0 updater. The tool successfully identified the device as firmware v0.13.1, transferred the main module and auxiliary files, and received a successful commit response. It then stopped at `prepare for firmware flashing...` and began reporting USB transfer errors. It never printed `now flashing...`, a reconnect confirmation, a new version, or a success result.

After complete power-off/power-on, Windows, usbipd, and WSL no longer enumerate USB VID:PID `2207:0019`. The device power indicator remains lit. Consequently, this is not a ROS, Docker, RViz, udev, or usbipd configuration issue: no host-side driver can communicate with a device absent from the Windows USB bus.

**Current disposition: do not retry firmware flashing or start the ROS driver. Request a vendor recovery procedure / RMA evaluation.**

## Device and host context

| Item | Observed value |
| --- | --- |
| Device | Manifold Odin1 (`2207:0019` when healthy) |
| Pre-update firmware | SoC `0.13.1`; daemon `0.6.1`; install `0.12.1`; MCU `1.5.2`; kernel `5.10.209` |
| Host | Windows 11, WSL2 Ubuntu 22.04, Docker, ROS 2 Humble |
| Update package | `odin1_firmware_update_pack_0.14.1_20260817_release.zip` |
| Package checksum (SHA-256) | `92ED797F89E778EE1E99A79B9C42DBC6900A1D4979272B4DEF4E36DAB0DC4CA1` |
| Update archive checksum (SHA-256) | `236ff5ea1ded1997549cca5bb0c05a28262ca6a1a47b54c04ccdc497997ac5c6` |
| Updater used | Official `odin1_firmware_update_tool_0.5.0_amd64` |
| Updater checksum (SHA-256) | `171b04741da85dd4aa26a17b2198e06c946954617fb9bcbde6969868a625ada2` |

## Timeline and exact updater result

1. ROS driver and RViz were stopped before starting the update.
2. Official updater v0.5.0 detected and opened the Odin1 successfully.
3. The updater read the device version successfully and selected the v0.13.1-compatible v0.5.0 update path.
4. Main module transfer reached 97.83% and reported `transfer new module 1 success.`
5. Both extra files reported success: `db.bin -> /userdata/slam/db.bin` and `feat.yml -> /userdata/slam/feat.yml`.
6. The updater reported `device commit upgrade procedure success.`
7. It printed `prepare for firmware flashing...`, then produced `LIBUSB_TRANSFER_ERROR`, `LIBUSB_TRANSFER_STALL`, and `LIBUSB_ERROR_NO_DEVICE`.
8. It did **not** print the vendor success sequence: `now flashing...`, `device rebooted && reconnected`, a new firmware version, or `firmware update success`.
9. The update process was later stopped after the device did not re-enumerate.
10. Multiple post-event checks show no `2207:0019` in Windows PnP, `usbipd list`, or WSL `lsusb`, including after a full device power cycle and Windows PnP scan.

## Evidence

The complete unmodified updater output is deliberately retained locally (not committed because it is runtime evidence):

```text
/root/projects/Odin1-Scene-Reconstruction/.staging/firmware/odin1_0.14.1/firmware_update.log
```

The decisive portion is:

```text
transfer new module 1 success.
transfer extra file db.bin success.
transfer extra file feat.yml success.
device commit upgrade procedure success.
prepare for firmware flashing...
... LIBUSB_TRANSFER_ERROR
... LIBUSB_TRANSFER_STALL
... LIBUSB_ERROR_NO_DEVICE
```

## What was ruled out after the incident

- Windows PnP rescan did not discover the device.
- `usbipd list` contains only a historical persisted name (`hawk`); it does not have a live `2207:0019` bus entry.
- WSL `lsusb` contains only root hubs; there is no device to attach or pass to Docker.
- A lit device LED establishes power, but does not establish USB SoC/PHY boot or enumeration.

## Requested vendor action

Please provide one of the following for an Odin1 that is powered (LED lit) but does not enumerate as `2207:0019` after a firmware update reached commit and lost USB before the flashing/reconnect confirmation:

1. A documented hardware recovery / bootloader entry method and the matching recovery utility; or
2. A vendor-specific low-level patch/reflash tool; or
3. RMA / return-for-repair instructions.

Please also advise whether the tool's behaviour at `prepare for firmware flashing...` followed by `LIBUSB_ERROR_NO_DEVICE` has a known recovery path. Do not advise another ordinary OTA retry until the device can enumerate.

## Repository safety note

The repository contains reproducible scripts, configurations, documentation, and the first-party live-map preview package. Firmware archives, updater binaries, sensor captures, runtime logs, maps, and build output are intentionally ignored: they are large, vendor-distributed, or contain incident evidence that should be provided directly to support rather than committed publicly.
