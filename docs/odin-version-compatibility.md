# Odin1 版本兼容性（实测，2026-09-09）

## Driver 与设备实测版本
来源：`logs/driver_core.log`（driver 与设备建立连接时打印）

| 项 | 值 |
|---|---|
| ROS Driver 版本 | **v0.14.3**（官方仓库 tag v0.14.3，commit `a592cf2`） |
| 设备上报 recommended firmware | **0.13.0** |
| kernel_version | V5.10.209 |
| mcu_version | V1.5.2 |
| soc_version | **V0.13.1**（设备固件主体） |
| Daemon_proc_version | V0.6.1 |
| slam_version | V0.12.1 |

## 结论
- 设备 soc V0.13.1 满足驱动要求（设备上报 recommended_firmware_version 0.13.0），**固件兼容，无需升级**。
- 官方 README 提及的版本要求与设备实测一致（README 标注 Driver v0.14.3 ↔ firmware v0.14.0 为发布时参考值；设备自身上报 0.13.0 recommended，二者兼容，未发现异常）。
- **固件升级属高风险操作**：本仓库不自动执行任何固件刷写。若未来需升级，请按 Manifold Tech 官方工具/流程人工执行并自行评估变砖风险。

## 复检方法
```bash
grep -E "ros_driver_version|recommended_firmware_version|soc_version|kernel_version" logs/driver_core.log
```
