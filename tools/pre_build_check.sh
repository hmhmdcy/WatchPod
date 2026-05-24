#!/bin/bash
# WatchPod 构建前预检查脚本
# 在 flutter build apk 之前运行，提前发现问题
# Usage:  cd ~/watchpod && source ~/.bashrc_flutter && bash tools/pre_build_check.sh

PASS=0
FAIL=0
ERRORS=""

check() {
    local name="$1"
    local cmd="$2"
    echo "🔍 [$name] ..."
    if eval "$cmd" 2>&1; then
        echo "  ✅ $name 通过"
        ((PASS++))
    else
        echo "  ❌ $name 失败"
        ((FAIL++))
        ERRORS="$ERRORS\n  - $name"
    fi
    echo ""
}

echo "═══════════════════════════════════"
echo "  WatchPod 构建前预检查"
echo "═══════════════════════════════════"
echo ""

# 1. Flutter 静态分析（只检查 error 级别，过滤 info/warning）
echo "─── 1. Flutter Analyze ───"
cd "$(dirname "$0")/.." 2>/dev/null || cd ~/watchpod
analyze_output=$(flutter analyze 2>&1)
analyze_exit=$?
# 检查是否有 error 级别的 issue
if echo "$analyze_output" | grep -q "error •\|Error:"; then
    echo "$analyze_output" | grep --color=never "error •\|Error:"
    echo "  ❌ Flutter analyze 发现错误"
    ((FAIL++))
    ERRORS="$ERRORS\n  - Flutter analyze 有错误"
elif [ "$analyze_exit" -ne 0 ] && [ "$analyze_exit" -ne 1 ]; then
    echo "  ❌ Flutter analyze 运行失败 (exit=$analyze_exit)"
    ((FAIL++))
    ERRORS="$ERRORS\n  - Flutter analyze 运行失败"
else
    issue_count=$(echo "$analyze_output" | grep -c " • " 2>/dev/null)
    echo "  ✅ Flutter analyze 通过（$issue_count 个 info/warning，无错误）"
    ((PASS++))
fi
echo ""

# 2. 单元测试（如果有的话）
echo "─── 2. Flutter Test ───"
if ls test/ 2>/dev/null | grep -q .; then
    # Use --no-pub to avoid native plugin build hangs in WSL
    if flutter test --no-pub --timeout 30s 2>&1 | tail -10; then
        echo "  ✅ 单元测试通过"
        ((PASS++))
    else
        echo "  ❌ 单元测试失败"
        ((FAIL++))
        ERRORS="$ERRORS\n  - 单元测试失败"
    fi
else
    echo "  ⏭️  暂无单元测试，跳过"
fi
echo ""

# 总结
echo "═══════════════════════════════════"
echo "  预检查结果: ✅ $PASS 通过 | ❌ $FAIL 失败"
echo "═══════════════════════════════════"
if [ "$FAIL" -gt 0 ]; then
    echo -e "问题清单:$ERRORS"
    echo ""
    echo "⚠️  建议先修复以上问题再构建 APK"
    exit 1
else
    echo ""
    echo "🎉 所有检查通过，可以构建 APK 了！"
    exit 0
fi
