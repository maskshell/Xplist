# GitHub Actions 工作流配置说明

## 概述

本项目使用 GitHub Actions 进行跨平台构建，支持 Windows、macOS 和 Linux 平台。

## 工作流文件

### 1. Windows 构建
- **windows.yml**: MSVC 构建 (Qt 5.15.2)
- **windows-mingw.yml**: MinGW 构建 (Qt 5.15.2)
- **运行环境**: Windows Server 2022
- **触发方式**: 手动触发 (`workflow_dispatch`)
- **编译器**: MSVC 2019/2022 或 MinGW 8.1.0
- **输出**: Windows 可执行文件 (.exe)

### 2. macOS 构建
- **macos.yml**: 标准 macOS 构建 (Qt 5.15.2)
- **macos1012.yml**: 兼容旧版本 macOS (Qt 5.9.9)
- **macos-universal.yml**: 通用二进制构建 (支持 Intel + Apple Silicon)
- **运行环境**: macOS 12
- **触发方式**: 手动触发 (`workflow_dispatch`)

### 3. Linux 构建 (`ubuntu.yml`)
- **运行环境**: Ubuntu 22.04 LTS
- **触发方式**: 手动触发 (`workflow_dispatch`)
- **Qt 版本**: 5.15.2
- **输出**: Linux AppImage

## 更新历史

### 2024年更新
- **Ubuntu**: 从 20.04 升级到 22.04 (避免退役警告)
- **Windows**: 从 Server 2019 升级到 Server 2022 (避免退役警告)
- **触发方式**: 所有工作流改为手动触发，节省 CI/CD 资源
- **Actions 版本**: 更新所有 Actions 到最新版本，避免弃用警告
  - `actions/checkout@v2` → `actions/checkout@v4`
  - `actions/upload-artifact@v2` → `actions/upload-artifact@v4`
  - `jurplel/install-qt-action@v2.13.0` → `jurplel/install-qt-action@v3.3.0`

### 退役环境说明
- **Ubuntu 20.04**: 将于 2025-04-15 退役
- **Windows Server 2019**: 已于 2025-06-30 退役

### Actions 版本更新说明
- **actions/checkout**: 从 v2 升级到 v4，提供更好的性能和安全性
- **actions/upload-artifact**: 从 v2 升级到 v4，修复了弃用警告
- **jurplel/install-qt-action**: 从 v2.13.0 升级到 v3.3.0，修复了 `set-output` 弃用警告和 `zstandard` 模块错误
- **svenstaro/upload-release-action**: 保持 v2 版本（最新稳定版）

## 手动触发构建

1. 进入 GitHub 仓库的 "Actions" 页面
2. 选择要运行的工作流
3. 点击 "Run workflow" 按钮
4. 选择分支并点击 "Run workflow"

## 构建产物

- **Windows**: `Xplist-Win64.zip`
- **macOS**: `Xplist_Mac-*.dmg`
- **Linux**: `Xplist-Linux-x86_64.AppImage`

## 注意事项

1. **手动触发**: 所有工作流都需要手动触发，不会自动运行
2. **资源优化**: 手动触发可以避免不必要的构建，节省 GitHub Actions 分钟数
3. **版本兼容**: 确保 Qt 版本与目标平台兼容
4. **依赖管理**: 各平台需要正确安装相应的依赖库

## 故障排除

### 常见问题
1. **构建失败**: 检查 Qt 版本兼容性
2. **依赖缺失**: 确保所有必要的库都已安装
3. **权限问题**: 检查文件权限和路径设置

### 调试建议
1. 查看 Actions 日志获取详细错误信息
2. 在本地环境测试构建脚本
3. 检查依赖库版本兼容性 