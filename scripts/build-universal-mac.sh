#!/bin/bash

# Universal macOS Build Script
# 基于 GitHub Actions 工作流的本地构建脚本

set -e  # 遇到错误时退出

# 配置变量
TARGET_NAME="Xplist"
QT_VERSION="5.15.2"
BUILD_DIR="bin/release"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要的工具
check_requirements() {
    print_info "检查构建环境..."
    
    # 检查 Qt
    if ! command -v qmake &> /dev/null; then
        print_error "qmake 未找到，请安装 Qt 5.15.2"
        exit 1
    fi
    
    # 检查 lipo
    if ! command -v lipo &> /dev/null; then
        print_error "lipo 工具未找到，这是 macOS 系统工具"
        exit 1
    fi
    
    # 检查 macdeployqt
    if ! command -v macdeployqt &> /dev/null; then
        print_error "macdeployqt 未找到，请确保 Qt 安装正确"
        exit 1
    fi
    
    print_info "构建环境检查通过"
}

# 清理之前的构建
clean_build() {
    print_info "清理之前的构建..."
    rm -rf bin/release/${TARGET_NAME}_x86_64.app
    rm -rf bin/release/${TARGET_NAME}_arm64.app
    rm -rf bin/release/${TARGET_NAME}.app
    rm -f bin/release/${TARGET_NAME}_universal
    rm -f bin/release/${TARGET_NAME}.dmg
    print_info "清理完成"
}

# 构建 x86_64 版本
build_x86_64() {
    print_info "开始构建 x86_64 版本..."
    
    # 设置 x86_64 环境变量
    export ARCHFLAGS="-arch x86_64"
    
    # 清理并重新构建
    make clean || true
    qmake
    make
    
    # 重命名 x86_64 版本
    if [ -d "$BUILD_DIR/${TARGET_NAME}.app" ]; then
        mv "$BUILD_DIR/${TARGET_NAME}.app" "$BUILD_DIR/${TARGET_NAME}_x86_64.app"
        print_info "x86_64 版本构建完成"
    else
        print_error "x86_64 版本构建失败"
        exit 1
    fi
}

# 构建 ARM64 版本
build_arm64() {
    print_info "开始构建 ARM64 版本..."
    
    # 设置 ARM64 环境变量
    export ARCHFLAGS="-arch arm64"
    
    # 清理并重新构建
    make clean || true
    qmake
    make
    
    # 重命名 ARM64 版本
    if [ -d "$BUILD_DIR/${TARGET_NAME}.app" ]; then
        mv "$BUILD_DIR/${TARGET_NAME}.app" "$BUILD_DIR/${TARGET_NAME}_arm64.app"
        print_info "ARM64 版本构建完成"
    else
        print_error "ARM64 版本构建失败"
        exit 1
    fi
}

# 创建通用二进制文件
create_universal() {
    print_info "创建通用二进制文件..."
    
    # 检查两个版本是否存在
    if [ ! -d "$BUILD_DIR/${TARGET_NAME}_x86_64.app" ]; then
        print_error "x86_64 版本不存在"
        exit 1
    fi
    
    if [ ! -d "$BUILD_DIR/${TARGET_NAME}_arm64.app" ]; then
        print_error "ARM64 版本不存在"
        exit 1
    fi
    
    # 创建通用二进制文件
    lipo -create \
        "$BUILD_DIR/${TARGET_NAME}_x86_64.app/Contents/MacOS/${TARGET_NAME}" \
        "$BUILD_DIR/${TARGET_NAME}_arm64.app/Contents/MacOS/${TARGET_NAME}" \
        -output "$BUILD_DIR/${TARGET_NAME}_universal"
    
    # 复制 ARM64 版本的 .app 结构作为基础
    cp -R "$BUILD_DIR/${TARGET_NAME}_arm64.app" "$BUILD_DIR/${TARGET_NAME}.app"
    
    # 替换为通用二进制文件
    cp "$BUILD_DIR/${TARGET_NAME}_universal" "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}"
    
    # 设置执行权限
    chmod +x "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}"
    
    print_info "通用二进制文件创建完成"
}

# 验证通用二进制文件
verify_universal() {
    print_info "验证通用二进制文件..."
    
    # 检查文件架构
    local archs=$(lipo -info "$BUILD_DIR/${TARGET_NAME}.app/Contents/MacOS/${TARGET_NAME}")
    print_info "二进制文件架构: $archs"
    
    # 检查是否包含两种架构
    if echo "$archs" | grep -q "x86_64" && echo "$archs" | grep -q "arm64"; then
        print_info "通用二进制文件验证成功"
    else
        print_error "通用二进制文件验证失败"
        exit 1
    fi
}

# 打包 DMG
package_dmg() {
    print_info "开始打包 DMG..."
    
    # 复制 Info.plist
    cp -f Info.plist "$BUILD_DIR/${TARGET_NAME}.app/Contents/Info.plist"
    
    # 使用 macdeployqt 打包
    macdeployqt "$BUILD_DIR/${TARGET_NAME}.app" -qmldir=. -verbose=1 -dmg
    
    if [ -f "$BUILD_DIR/${TARGET_NAME}.dmg" ]; then
        print_info "DMG 打包完成: $BUILD_DIR/${TARGET_NAME}.dmg"
    else
        print_error "DMG 打包失败"
        exit 1
    fi
}

# 显示构建信息
show_build_info() {
    print_info "构建完成！"
    echo ""
    echo "构建产物:"
    echo "  - 通用 DMG: $BUILD_DIR/${TARGET_NAME}.dmg"
    echo "  - x86_64 版本: $BUILD_DIR/${TARGET_NAME}_x86_64.app"
    echo "  - ARM64 版本: $BUILD_DIR/${TARGET_NAME}_arm64.app"
    echo ""
    echo "DMG 文件大小:"
    ls -lh "$BUILD_DIR/${TARGET_NAME}.dmg" 2>/dev/null || echo "DMG 文件不存在"
}

# 主函数
main() {
    print_info "开始 Universal macOS 构建..."
    print_info "目标: $TARGET_NAME"
    print_info "Qt 版本: $QT_VERSION"
    
    # 检查构建环境
    check_requirements
    
    # 清理之前的构建
    clean_build
    
    # 构建 x86_64 版本
    build_x86_64
    
    # 构建 ARM64 版本
    build_arm64
    
    # 创建通用二进制文件
    create_universal
    
    # 验证通用二进制文件
    verify_universal
    
    # 打包 DMG
    package_dmg
    
    # 显示构建信息
    show_build_info
}

# 处理命令行参数
case "${1:-}" in
    "clean")
        clean_build
        exit 0
        ;;
    "x86_64")
        check_requirements
        clean_build
        build_x86_64
        exit 0
        ;;
    "arm64")
        check_requirements
        clean_build
        build_arm64
        exit 0
        ;;
    "verify")
        verify_universal
        exit 0
        ;;
    "help"|"-h"|"--help")
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  clean    清理构建产物"
        echo "  x86_64   只构建 x86_64 版本"
        echo "  arm64    只构建 ARM64 版本"
        echo "  verify   验证通用二进制文件"
        echo "  help     显示此帮助信息"
        echo ""
        echo "默认行为: 构建完整的通用二进制文件"
        exit 0
        ;;
    "")
        # 默认行为：构建完整版本
        main
        ;;
    *)
        print_error "未知选项: $1"
        echo "使用 '$0 help' 查看帮助信息"
        exit 1
        ;;
esac 