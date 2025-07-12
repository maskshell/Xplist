#!/bin/bash

# Xplist 构建清理脚本
# 清理所有构建产物和临时文件

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

print_header "开始清理构建产物"

# 1. 清理 Qt 生成的 MOC 文件
print_info "清理 MOC 文件..."
rm -f moc_*.cpp
rm -f moc_*.h
rm -f moc_*.o

# 2. 清理 UI 生成的文件
print_info "清理 UI 生成文件..."
rm -f ui_*.h

# 3. 清理资源文件
print_info "清理资源文件..."
rm -f qrc_*.cpp
rm -f qrc_*.o

# 4. 清理目标文件
print_info "清理目标文件..."
rm -f *.o
rm -f *.obj

# 5. 清理可执行文件
print_info "清理可执行文件..."
rm -f Xplist
rm -f Xplist.exe
rm -f *.exe
rm -f *.app

# 6. 清理构建目录
print_info "清理构建目录..."
rm -rf bin/
rm -rf build/
rm -rf debug/
rm -rf release/
rm -rf obj/

# 7. 清理 Qt 项目文件
print_info "清理 Qt 项目文件..."
rm -f .qmake.stash
rm -f Makefile*
rm -f *.pro.user
rm -f *.pro.user.*

# 8. 清理临时文件
print_info "清理临时文件..."
rm -f *.tmp
rm -f *.temp
rm -f *.log
rm -f *.bak
rm -f *.backup

# 9. 清理 OS 生成的文件
print_info "清理系统文件..."
find . -name ".DS_Store" -delete
find . -name "Thumbs.db" -delete
find . -name "ehthumbs.db" -delete

# 10. 清理 IDE 文件
print_info "清理 IDE 文件..."
rm -rf .vscode/
rm -rf .idea/
rm -f *.swp
rm -f *.swo
rm -f *~

# 11. 清理翻译文件
print_info "清理翻译文件..."
rm -f *.qm

# 12. 清理网络分析报告（临时文件）
print_info "清理临时分析文件..."
rm -f network_analysis_report.md

print_header "清理完成"

# 显示清理结果
print_info "当前目录文件："
ls -la | grep -E "\.(cpp|h|ui|pro|qrc|ts)$" || echo "没有源代码文件"

print_info "构建产物已清理完毕！"
print_info "现在可以重新构建项目："
echo "  qmake"
echo "  make" 