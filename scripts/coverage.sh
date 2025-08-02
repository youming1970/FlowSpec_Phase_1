#!/bin/bash

# FlowSpec CLI 测试覆盖率脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}
# 在开发阶段，如果设置了 DEV_MODE，使用较低的阈值
if [ "${DEV_MODE}" = "true" ]; then
    COVERAGE_THRESHOLD=0
    echo -e "${YELLOW}⚠️  开发模式：覆盖率阈值设置为 ${COVERAGE_THRESHOLD}%${NC}"
fi
COVERAGE_FILE="coverage.out"
COVERAGE_HTML="coverage.html"

echo "🧪 运行测试并生成覆盖率报告..."

# 运行测试并生成覆盖率
go test -v -race -coverprofile=$COVERAGE_FILE ./...

if [ ! -f "$COVERAGE_FILE" ]; then
    echo -e "${RED}❌ 覆盖率文件未生成${NC}"
    exit 1
fi

# 生成HTML报告
go tool cover -html=$COVERAGE_FILE -o $COVERAGE_HTML
echo -e "${GREEN}📊 HTML覆盖率报告已生成: $COVERAGE_HTML${NC}"

# 计算总覆盖率
COVERAGE=$(go tool cover -func=$COVERAGE_FILE | grep total | awk '{print substr($3, 1, length($3)-1)}')

echo ""
echo "📈 测试覆盖率报告:"
echo "===================="

# 显示每个包的覆盖率
go tool cover -func=$COVERAGE_FILE | grep -v total

echo "===================="
echo -e "总覆盖率: ${YELLOW}${COVERAGE}%${NC}"

# 检查是否达到阈值
if (( $(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
    echo -e "${RED}❌ 测试覆盖率 ${COVERAGE}% 低于要求的 ${COVERAGE_THRESHOLD}%${NC}"
    echo ""
    echo "💡 提示: 请为以下文件添加更多测试:"
    go tool cover -func=$COVERAGE_FILE | awk -v threshold=$COVERAGE_THRESHOLD '
    $3 != "total:" && substr($3, 1, length($3)-1) < threshold {
        print "  - " $1 " (" $3 ")"
    }'
    exit 1
else
    echo -e "${GREEN}✅ 测试覆盖率 ${COVERAGE}% 符合要求 (>= ${COVERAGE_THRESHOLD}%)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 覆盖率检查通过！${NC}"