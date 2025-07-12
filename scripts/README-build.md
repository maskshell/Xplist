# Xplist 构建指南

## 概述

本项目已经优化了构建配置，确保所有构建产物都放在正确的位置，避免源代码目录被污染。

## 📁 目录结构

```
Xplist/
├── bin/                    # 构建产物目录
│   ├── debug/             # Debug 版本构建产物
│   │   ├── obj/          # 目标文件
│   │   ├── moc/          # MOC 生成文件
│   │   ├── rcc/          # 资源文件
│   │   ├── ui/           # UI 生成文件
│   │   └── Xplist        # 可执行文件
│   └── release/          # Release 版本构建产物
│       ├── obj/          # 目标文件
│       ├── moc/          # MOC 生成文件
│       ├── rcc/          # 资源文件
│       ├── ui/           # UI 生成文件
│       ├── Xplist        # 可执行文件
│       ├── Xplist.app    # macOS 应用包
│       └── Xplist.dmg    # macOS 安装包
├── scripts/              # 构建脚本
│   ├── build.sh          # 构建脚本
│   ├── clean-build.sh    # 清理脚本
│   └── README-build.md   # 本文档
└── .gitignore           # Git 忽略文件
```

## 🛠️ 构建脚本

### 1. 清理构建产物
```bash
./scripts/clean-build.sh
```

**功能：**
- 清理所有构建产物和临时文件
- 清理 Qt 生成的 MOC、UI、资源文件
- 清理目标文件和可执行文件
- 清理系统生成的文件

### 2. 构建项目
```bash
# Release 版本（默认）
./scripts/build.sh

# Debug 版本
./scripts/build.sh debug

# Release 版本（明确指定）
./scripts/build.sh release
```

**功能：**
- 自动清理之前的构建
- 运行 qmake 生成 Makefile
- 运行 make 编译项目
- 检查构建产物
- 显示构建结果

## 🔧 手动构建

如果不想使用脚本，也可以手动构建：

```bash
# 1. 清理之前的构建
rm -rf bin/

# 2. 运行 qmake
qmake CONFIG+=release  # 或 CONFIG+=debug

# 3. 运行 make
make

# 4. 检查构建产物
ls -la bin/release/
```

## 📋 构建产物说明

### Debug 版本
- **位置**: `bin/debug/`
- **用途**: 开发和调试
- **特点**: 包含调试信息，未优化

### Release 版本
- **位置**: `bin/release/`
- **用途**: 生产环境
- **特点**: 优化编译，体积更小

### macOS 特定产物
- **Xplist.app**: macOS 应用包
- **Xplist.dmg**: macOS 安装包
- **Xplist**: 可执行文件

## 🚀 运行应用

构建完成后，可以运行应用：

```bash
# 运行 Release 版本
./bin/release/Xplist

# 运行 Debug 版本
./bin/debug/Xplist

# 在 macOS 上打开应用包
open bin/release/Xplist.app
```

## 🔍 故障排除

### 1. Qt 环境问题
```bash
# 检查 Qt 环境
qmake --version
which qmake

# 如果未找到，设置环境变量
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
```

### 2. 构建失败
```bash
# 清理后重新构建
./scripts/clean-build.sh
./scripts/build.sh
```

### 3. 权限问题
```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh
```

### 4. 依赖问题
```bash
# 安装 Qt 依赖
brew install qt@5
```

## 📝 注意事项

1. **构建产物位置**: 所有构建产物都放在 `bin/` 目录下
2. **源代码保护**: 使用 `.gitignore` 保护源代码不被构建产物污染
3. **清理脚本**: 定期运行清理脚本保持目录整洁
4. **版本控制**: 构建产物不会被提交到 Git 仓库

## 🎯 最佳实践

1. **开发时**: 使用 Debug 版本进行开发和调试
2. **发布时**: 使用 Release 版本进行打包和分发
3. **定期清理**: 定期运行清理脚本
4. **版本控制**: 只提交源代码，不提交构建产物

## 📞 支持

如果遇到构建问题，请检查：
1. Qt 环境是否正确配置
2. 是否有足够的磁盘空间
3. 是否有正确的权限
4. 依赖库是否完整安装 