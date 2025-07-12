#!/bin/bash

# Universal macOS 构建脚本 - ARM64 Mac 版本
# 注意：在 ARM64 Mac 上无法直接构建 x86_64 版本

set -e

TARGET_NAME="Xplist"
BUILD_DIR="bin/release"

echo "🚀 开始 Universal macOS 构建 (ARM64 Mac)"
echo ""
echo "⚠️  重要提示："
echo "   在 ARM64 Mac 上无法直接构建 x86_64 版本"
echo "   需要以下方案之一："
echo "   1. 使用 Rosetta 2 模拟 x86_64 环境"
echo "   2. 在 Intel Mac 或虚拟机中构建 x86_64 版本"
echo "   3. 使用 GitHub Actions 进行跨平台构建"
echo ""

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

# 验证 ARM64 版本
echo "🔍 验证 ARM64 版本..."
ARCHS=$(lipo -info "$BUILD_DIR/${TARGET_NAME}_arm64.app/Contents/MacOS/${TARGET_NAME}")
echo "📋 ARM64 二进制文件架构: $ARCHS"

# 尝试使用 Rosetta 2 构建 x86_64 版本
echo ""
echo "🔄 尝试使用 Rosetta 2 构建 x86_64 版本..."
echo "   这可能需要一些时间..."

# 检查是否安装了 Rosetta 2
if ! arch -x86_64 /usr/bin/true &> /dev/null; then
    echo "❌ 未安装 Rosetta 2，无法构建 x86_64 版本"
    echo "   请运行: softwareupdate --install-rosetta"
    echo ""
    echo "📦 仅构建 ARM64 版本..."
    
    # 复制 ARM64 版本作为最终版本
    cp -R "$BUILD_DIR/${TARGET_NAME}_arm64.app" "$BUILD_DIR/${TARGET_NAME}.app"
    
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
    echo "  - ARM64 DMG: $BUILD_DIR/${TARGET_NAME}.dmg"
    echo "  - ARM64 版本: $BUILD_DIR/${TARGET_NAME}_arm64.app"
    echo ""
    echo "📊 DMG 文件大小:"
    ls -lh "$BUILD_DIR/${TARGET_NAME}.dmg"
    echo ""
    echo "💡 提示：如需通用二进制文件，请使用 GitHub Actions 或 Intel Mac"
    
    exit 0
fi

# 使用 Rosetta 2 构建 x86_64 版本
echo "🔨 使用 Rosetta 2 构建 x86_64 版本..."
arch -x86_64 bash -c "
    export PATH=\"/opt/homebrew/opt/qt@5/bin:\$PATH\"
    export ARCHFLAGS=\"-arch x86_64\"
    cd $(pwd)
    make clean || true
    qmake
    make
"

if [ -d "$BUILD_DIR/${TARGET_NAME}.app" ]; then
    mv "$BUILD_DIR/${TARGET_NAME}.app" "$BUILD_DIR/${TARGET_NAME}_x86_64.app"
    echo "✅ x86_64 版本构建完成"
else
    echo "❌ x86_64 版本构建失败"
    echo "   将仅使用 ARM64 版本"
    cp -R "$BUILD_DIR/${TARGET_NAME}_arm64.app" "$BUILD_DIR/${TARGET_NAME}.app"
fi

# 验证 x86_64 版本
if [ -d "$BUILD_DIR/${TARGET_NAME}_x86_64.app" ]; then
    echo "🔍 验证 x86_64 版本..."
    ARCHS=$(lipo -info "$BUILD_DIR/${TARGET_NAME}_x86_64.app/Contents/MacOS/${TARGET_NAME}")
    echo "📋 x86_64 二进制文件架构: $ARCHS"
    
    # 检查是否真的是 x86_64
    if echo "$ARCHS" | grep -q "x86_64"; then
        echo "✅ x86_64 版本验证成功"
        
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
        echo "📋 通用二进制文件架构: $ARCHS"
        
        if echo "$ARCHS" | grep -q "x86_64" && echo "$ARCHS" | grep -q "arm64"; then
            echo "✅ 通用二进制文件验证成功"
        else
            echo "❌ 通用二进制文件验证失败"
            exit 1
        fi
    else
        echo "⚠️  x86_64 版本仍然是 ARM64，将仅使用 ARM64 版本"
        cp -R "$BUILD_DIR/${TARGET_NAME}_arm64.app" "$BUILD_DIR/${TARGET_NAME}.app"
    fi
else
    echo "⚠️  没有 x86_64 版本，将仅使用 ARM64 版本"
    cp -R "$BUILD_DIR/${TARGET_NAME}_arm64.app" "$BUILD_DIR/${TARGET_NAME}.app"
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
echo "  - 最终 DMG: $BUILD_DIR/${TARGET_NAME}.dmg"
echo "  - ARM64 版本: $BUILD_DIR/${TARGET_NAME}_arm64.app"

if [ -d "$BUILD_DIR/${TARGET_NAME}_x86_64.app" ]; then
    echo "  - x86_64 版本: $BUILD_DIR/${TARGET_NAME}_x86_64.app"
fi

if [ -f "$BUILD_DIR/${TARGET_NAME}_universal" ]; then
    echo "  - 通用二进制文件: $BUILD_DIR/${TARGET_NAME}_universal"
fi

echo ""
echo "📊 DMG 文件大小:"
ls -lh "$BUILD_DIR/${TARGET_NAME}.dmg"

# 显示架构信息
echo ""
echo "🔍 最终二进制文件架构:"
lipo -info "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}" 