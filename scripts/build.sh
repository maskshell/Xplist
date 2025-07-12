#!/bin/bash

# Xplist 构建脚本
# 确保所有构建产物都放在正确的位置

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# 检查是否在项目根目录
if [ ! -f "Xplist.pro" ]; then
    print_error "请在 Xplist 项目根目录运行此脚本"
    exit 1
fi

# 检查 Qt 环境
if ! command -v qmake &> /dev/null; then
    print_error "qmake 未找到，请确保 Qt 环境已正确配置"
    exit 1
fi

print_header "开始构建 Xplist"

# 获取构建类型
BUILD_TYPE=${1:-release}
if [ "$BUILD_TYPE" != "debug" ] && [ "$BUILD_TYPE" != "release" ]; then
    print_error "无效的构建类型: $BUILD_TYPE"
    print_info "使用: debug 或 release"
    exit 1
fi

print_info "构建类型: $BUILD_TYPE"

# 清理之前的构建
print_info "清理之前的构建..."
if [ "$BUILD_TYPE" = "debug" ]; then
    rm -rf bin/debug/
else
    rm -rf bin/release/
fi

# 运行 qmake
print_info "运行 qmake..."
if [ "$BUILD_TYPE" = "debug" ]; then
    qmake CONFIG+=debug
else
    qmake CONFIG+=release
fi

# 检查 qmake 是否成功
if [ $? -ne 0 ]; then
    print_error "qmake 失败"
    exit 1
fi

# 运行 make
print_info "运行 make..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# 检查 make 是否成功
if [ $? -ne 0 ]; then
    print_error "make 失败"
    exit 1
fi

print_header "构建完成"

# 检查构建产物
print_info "检查构建产物..."
if [ "$BUILD_TYPE" = "debug" ]; then
    BUILD_DIR="bin/debug"
else
    BUILD_DIR="bin/release"
fi

if [ -d "$BUILD_DIR" ]; then
    print_info "构建目录: $BUILD_DIR"
    ls -la "$BUILD_DIR"
    
    # 检查可执行文件
    if [ -f "$BUILD_DIR/Xplist" ]; then
        print_info "✅ 可执行文件已生成: $BUILD_DIR/Xplist"
        file "$BUILD_DIR/Xplist"
    elif [ -f "$BUILD_DIR/Xplist.exe" ]; then
        print_info "✅ 可执行文件已生成: $BUILD_DIR/Xplist.exe"
        file "$BUILD_DIR/Xplist.exe"
    else
        print_warning "⚠️  未找到可执行文件"
    fi
    
    # 检查 .app 文件 (macOS)
    if [ -d "$BUILD_DIR/Xplist.app" ]; then
        print_info "✅ macOS 应用已生成: $BUILD_DIR/Xplist.app"
    fi
    
    # 检查 DMG 文件
    if [ -f "$BUILD_DIR/Xplist.dmg" ]; then
        print_info "✅ DMG 安装包已生成: $BUILD_DIR/Xplist.dmg"
        ls -lh "$BUILD_DIR/Xplist.dmg"
    fi
else
    print_error "构建目录不存在: $BUILD_DIR"
    exit 1
fi

print_header "构建成功"

print_info "构建产物位置: $BUILD_DIR"
print_info "可以运行: ./$BUILD_DIR/Xplist" 