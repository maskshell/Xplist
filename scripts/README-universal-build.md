# Universal macOS 本地构建指南

本指南介绍如何在 Mac 本地执行 Universal 构建，生成同时支持 Intel (x86_64) 和 Apple Silicon (ARM64) 的通用二进制文件。

## ⚠️ ARM64 Mac 限制

**重要提示**：在 ARM64 Mac (Apple Silicon) 上存在以下限制：

1. **无法直接构建 x86_64 版本**：即使设置 `ARCHFLAGS="-arch x86_64"`，编译器仍会生成 ARM64 代码
2. **需要 Rosetta 2**：要构建 x86_64 版本，需要安装 Rosetta 2 并使用 `arch -x86_64` 命令
3. **推荐使用 GitHub Actions**：最可靠的方案是使用 GitHub Actions 进行跨平台构建

## 前置要求

### 1. 安装 Qt 5.15.2
```bash
# 使用 Homebrew 安装 Qt
brew install qt@5

# 或者从 Qt 官网下载安装包
# https://www.qt.io/download
```

### 2. 设置 Qt 环境变量
```bash
# 将 Qt 添加到 PATH
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"

# 或者添加到 ~/.zshrc 或 ~/.bash_profile
echo 'export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 3. 验证 Qt 安装
```bash
qmake --version
macdeployqt --version
```

### 4. 安装 Rosetta 2 (ARM64 Mac 需要)
```bash
# 检查是否已安装 Rosetta 2
arch -x86_64 /usr/bin/true

# 如果未安装，运行以下命令
softwareupdate --install-rosetta
```

## 构建脚本

### 1. ARM64 Mac 专用脚本 (推荐)
```bash
# 执行适合 ARM64 Mac 的构建
./scripts/build-universal-arm64-mac.sh
```

### 2. 简化版构建脚本
```bash
# 执行完整的 Universal 构建
./scripts/build-universal-simple.sh
```

### 3. 完整版构建脚本 (功能更丰富)
```bash
# 执行完整的 Universal 构建
./scripts/build-universal-mac.sh

# 只构建 x86_64 版本
./scripts/build-universal-mac.sh x86_64

# 只构建 ARM64 版本
./scripts/build-universal-mac.sh arm64

# 清理构建产物
./scripts/build-universal-mac.sh clean

# 验证通用二进制文件
./scripts/build-universal-mac.sh verify

# 查看帮助
./scripts/build-universal-mac.sh help
```

## 不同 Mac 架构的构建方案

### ARM64 Mac (Apple Silicon)
```bash
# 方案 1: 仅构建 ARM64 版本
./scripts/build-universal-arm64-mac.sh

# 方案 2: 使用 Rosetta 2 构建通用版本
# (需要先安装 Rosetta 2)
./scripts/build-universal-arm64-mac.sh

# 方案 3: 使用 GitHub Actions
# 推送代码到 GitHub，使用 .github/workflows/macos-universal.yml
```

### Intel Mac (x86_64)
```bash
# 可以直接构建通用版本
./scripts/build-universal-simple.sh
```

## 构建过程说明

### ARM64 Mac 上的构建过程
```bash
# 步骤 1: 构建 ARM64 版本
export ARCHFLAGS="-arch arm64"
qmake
make

# 步骤 2: 使用 Rosetta 2 构建 x86_64 版本
arch -x86_64 bash -c "
    export PATH=\"/opt/homebrew/opt/qt@5/bin:\$PATH\"
    export ARCHFLAGS=\"-arch x86_64\"
    qmake
    make
"

# 步骤 3: 创建通用二进制文件
lipo -create \
    bin/release/Xplist_x86_64.app/Contents/MacOS/Xplist \
    bin/release/Xplist_arm64.app/Contents/MacOS/Xplist \
    -output bin/release/Xplist_universal
```

### Intel Mac 上的构建过程
```bash
# 步骤 1: 构建 x86_64 版本
export ARCHFLAGS="-arch x86_64"
qmake
make

# 步骤 2: 构建 ARM64 版本
export ARCHFLAGS="-arch arm64"
qmake
make

# 步骤 3: 创建通用二进制文件
lipo -create \
    bin/release/Xplist_x86_64.app/Contents/MacOS/Xplist \
    bin/release/Xplist_arm64.app/Contents/MacOS/Xplist \
    -output bin/release/Xplist_universal
```

## 构建产物

### ARM64 Mac 构建产物
```
bin/release/
├── Xplist.dmg                    # ARM64 DMG 安装包
├── Xplist.app/                   # ARM64 应用
└── Xplist_arm64.app/            # ARM64 版本
```

### 成功构建通用版本的产物
```
bin/release/
├── Xplist.dmg                    # 通用 DMG 安装包
├── Xplist.app/                   # 通用应用 (包含 x86_64 + ARM64)
├── Xplist_x86_64.app/           # 仅 x86_64 版本
├── Xplist_arm64.app/            # 仅 ARM64 版本
└── Xplist_universal             # 通用二进制文件
```

## 故障排除

### 1. ARM64 Mac 特定问题
```bash
# 问题：无法构建 x86_64 版本
# 解决：安装 Rosetta 2
softwareupdate --install-rosetta

# 问题：Rosetta 2 构建失败
# 解决：检查 Qt 环境变量
arch -x86_64 bash -c "qmake --version"
```

### 2. Qt 环境问题
```bash
# 检查 Qt 安装
which qmake
which macdeployqt

# 如果找不到，重新设置 PATH
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
```

### 3. 构建失败
```bash
# 清理并重新构建
make clean
./scripts/build-universal-arm64-mac.sh
```

### 4. 架构验证失败
```bash
# 手动验证二进制文件架构
lipo -info bin/release/Xplist.app/Contents/MacOS/Xplist

# 应该显示架构信息
```

## 推荐方案

### 对于 ARM64 Mac 用户
1. **开发测试**：使用 `build-universal-arm64-mac.sh` 构建 ARM64 版本
2. **发布版本**：使用 GitHub Actions 构建通用版本
3. **完整测试**：在 Intel Mac 或虚拟机中测试 x86_64 兼容性

### 对于 Intel Mac 用户
1. **本地开发**：使用 `build-universal-simple.sh` 构建通用版本
2. **发布版本**：使用 GitHub Actions 确保一致性

## 性能优化

### 1. 并行构建 (仅 Intel Mac)
```bash
# 在第一个终端构建 x86_64
export ARCHFLAGS="-arch x86_64"
qmake && make

# 在第二个终端构建 ARM64
export ARCHFLAGS="-arch arm64"
qmake && make
```

### 2. 缓存优化
```bash
# 使用 ccache 加速编译
brew install ccache
export CC="ccache gcc"
export CXX="ccache g++"
```

## 与 GitHub Actions 的对比

| 特性 | 本地构建 | GitHub Actions |
|------|----------|----------------|
| **构建时间** | 取决于本地性能 | 约 10-15 分钟 |
| **资源消耗** | 使用本地资源 | 使用 GitHub 资源 |
| **调试能力** | 可以实时调试 | 只能查看日志 |
| **网络依赖** | 无 | 需要下载 Qt |
| **ARM64 Mac 支持** | 有限制 | 完整支持 |
| **成本** | 免费 | 免费 (开源项目) |

## 注意事项

1. **磁盘空间**: Universal 构建需要更多磁盘空间，确保有足够的空间
2. **构建时间**: 完整构建可能需要 10-30 分钟，取决于您的 Mac 性能
3. **内存使用**: 构建过程中会使用较多内存，建议关闭其他应用
4. **网络连接**: 首次构建可能需要下载 Qt 依赖
5. **ARM64 Mac 限制**: 在 ARM64 Mac 上构建 x86_64 版本需要 Rosetta 2

## 相关文件

- `.github/workflows/macos-universal.yml` - GitHub Actions 工作流
- `scripts/build-universal-arm64-mac.sh` - ARM64 Mac 专用构建脚本
- `scripts/build-universal-simple.sh` - 简化版构建脚本
- `scripts/build-universal-mac.sh` - 完整版构建脚本
- `Xplist.pro` - Qt 项目文件
- `Info.plist` - macOS 应用信息文件 