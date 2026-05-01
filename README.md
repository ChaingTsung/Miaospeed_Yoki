# Miaospeed 自动化编译发行版

这是由 GitHub Actions 自动化构建的 `miaospeed` 服务端程序。已内置所需的 mTLS 证书与验证配置。

## 支持的平台架构
- **Linux (VPS / 开发板 / 软路由)**: 
  - `amd64` (常规Intel/AMD服务器)
  - `arm64` (Rockchip RK3588/RK3568, 树莓派4/5, Oracle ARM等64位设备)
  - `arm` (老旧32位ARM设备或电视盒子)
  - `mipsle` (部分基于 OpenWrt 的路由器)

## 编译信息
- **构建时间**: 2026-05-01 03:57:15 UTC
- **当前 BUILD TOKEN**: 
```text
d68ef58547ba4879|23bc52dd06af450c|f670adb72830463a|3dd2ba69a92d4e85|2afb8b1a4a7c4d02|3bc45c743fba4ee4|6c4916963e5b465a|a78914a438454360
```

*此 TOKEN 已固定。如果需要更换，请在触发 Actions 时勾选「强制重新生成 TOKEN」选项。*
