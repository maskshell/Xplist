#!/bin/bash

# 简化的 Universal macOS 构建脚本
# 专门针对 ARM64 Mac 优化

set -e

TARGET_NAME="Xplist"
BUILD_DIR="bin/release"

echo "🚀 开始 Universal macOS 构建..."

# 检查 Qt 环境
if ! command -v qmake &> /dev/null; then
    echo "❌ 错误: 未找到 qmake，请安装 Qt 5.15.2"
    exit 1
fi

echo "✅ Qt 环境检查通过"

# 清理之前的构建
echo "🧹 清理之前的构建..."
rm -rf "$BUILD_DIR/${TARGET_NAME}_x86_64.app"
rm -rf "$BUILD_DIR/${TARGET_NAME}_arm64.app"
rm -rf "$BUILD_DIR/${TARGET_NAME}.app"
rm -f "$BUILD_DIR/${TARGET_NAME}_universal"
rm -f "$BUILD_DIR/${TARGET_NAME}.dmg"

# 构建 x86_64 版本
echo "🔨 构建 x86_64 版本..."
export ARCHFLAGS="-arch x86_64"
make clean || true
qmake
make

if [ -d "$BUILD_DIR/${TARGET_NAME}.app" ]; then
    mv "$BUILD_DIR/${TARGET_NAME}.app" "$BUILD_DIR/${TARGET_NAME}_x86_64.app"
    echo "✅ x86_64 版本构建完成"
else
    echo "❌ x86_64 版本构建失败"
    exit 1
fi

# 构建 ARM64 版本
echo "🔨 构建 ARM64 版本..."
export ARCHFLAGS="-arch arm64"
make clean || true
qmake
make

if [ -d "$BUILD_DIR/${TARGET_NAME}.app" ]; then
    mv "$BUILD_DIR/${TARGET_NAME}.app" "$BUILD_DIR/${TARGET_NAME}_arm64.app"
    echo "✅ ARM64 版本构建完成"
else
    echo "❌ ARM64 版本构建失败"
    exit 1
fi

# 创建通用二进制文件
echo "🔗 创建通用二进制文件..."
lipo -create \
    "$BUILD_DIR/${TARGET_NAME}_x86_64.app/Contents/MacOS/${TARGET_NAME}" \
    "$BUILD_DIR/${TARGET_NAME}_arm64.app/Contents/MacOS/${TARGET_NAME}" \
    -output "$BUILD_DIR/${TARGET_NAME}_universal"

# 复制 ARM64 版本的 .app 结构
cp -R "$BUILD_DIR/${TARGET_NAME}_arm64.app" "$BUILD_DIR/${TARGET_NAME}.app"

# 替换为通用二进制文件
cp "$BUILD_DIR/${TARGET_NAME}_universal" "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}"
chmod +x "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}"

echo "✅ 通用二进制文件创建完成"

# 验证通用二进制文件
echo "🔍 验证通用二进制文件..."
ARCHS=$(lipo -info "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}")
echo "📋 二进制文件架构: $ARCHS"

if echo "$ARCHS" | grep -q "x86_64" && echo "$ARCHS" | grep -q "arm64"; then
    echo "✅ 通用二进制文件验证成功"
else
    echo "❌ 通用二进制文件验证失败"
    exit 1
fi

# 打包 DMG
echo "📦 开始打包 DMG..."
cp -f Info.plist "$BUILD_DIR/${TARGET_NAME}.app/Contents/Info.plist"
macdeployqt "$BUILD_DIR/${TARGET_NAME}.app" -qmldir=. -verbose=1 -dmg

if [ -f "$BUILD_DIR/${TARGET_NAME}.dmg" ]; then
    echo "✅ DMG 打包完成: $BUILD_DIR/${TARGET_NAME}.dmg"
else
    echo "❌ DMG 打包失败"
    exit 1
fi

# 显示构建结果
echo ""
echo "🎉 构建完成！"
echo ""
echo "📁 构建产物:"
echo "  - 通用 DMG: $BUILD_DIR/${TARGET_NAME}.dmg"
echo "  - x86_64 版本: $BUILD_DIR/${TARGET_NAME}_x86_64.app"
echo "  - ARM64 版本: $BUILD_DIR/${TARGET_NAME}_arm64.app"
echo ""
echo "📊 DMG 文件大小:"
ls -lh "$BUILD_DIR/${TARGET_NAME}.dmg" 