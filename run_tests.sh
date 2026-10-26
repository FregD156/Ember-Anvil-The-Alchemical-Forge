#!/usr/bin/env bash

# ==============================================================================
# Script chạy toàn bộ bài kiểm thử tự động (Unit Tests) cho Ember & Anvil
# Sử dụng: ./run_tests.sh
# ==============================================================================

set -e

# Màu hiển thị
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  Ember & Anvil: The Alchemical Forge - Test Suite    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Tìm đường dẫn Godot khả dụng
GODOT_BIN=""
if command -v godot &> /dev/null; then
    GODOT_BIN="godot"
elif [ -f "/opt/homebrew/bin/godot" ]; then
    GODOT_BIN="/opt/homebrew/bin/godot"
elif [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -f "/usr/local/bin/godot" ]; then
    GODOT_BIN="/usr/local/bin/godot"
fi

if [ -z "$GODOT_BIN" ]; then
    echo -e "${RED}❌ Lỗi: Không tìm thấy Godot trên hệ thống!${NC}"
    echo "Vui lòng cài đặt Godot 4 hoặc thêm godot vào biến môi trường PATH."
    exit 1
fi

echo -e "⚙️ Sử dụng Godot tại: ${GREEN}$GODOT_BIN${NC}"
echo -e "🚀 Đang thực thi bộ test không giao diện (headless mode)...\n"

# Chạy test scene
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" "res://tests/test_runner.tscn"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}🎉 TẤT CẢ CÁC BÀI TEST ĐÃ HOÀN TẤT THÀNH CÔNG!${NC}"
else
    echo -e "\n${RED}❌ Có lỗi xảy ra trong quá trình chạy test (Mã lỗi: $EXIT_CODE).${NC}"
fi

exit $EXIT_CODE
