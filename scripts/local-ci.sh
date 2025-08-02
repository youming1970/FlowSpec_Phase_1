#!/bin/bash

# 本地 CI 测试脚本 - 模拟 GitHub Actions 工作流

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 FlowSpec CLI 本地 CI 测试${NC}"
echo "================================"

# 步骤1: 代码格式检查
echo ""
echo -e "${YELLOW}📝 步骤1: 代码格式检查${NC}"
if make fmt; then
    echo -e "${GREEN}✅ 代码格式检查通过${NC}"
else
    echo -e "${RED}❌ 代码格式检查失败${NC}"
    exit 1
fi

# 步骤2: 代码静态分析
echo ""
echo -e "${YELLOW}🔍 步骤2: 代码静态分析${NC}"
if make vet; then
    echo -e "${GREEN}✅ 代码静态分析通过${NC}"
else
    echo -e "${RED}❌ 代码静态分析失败${NC}"
    exit 1
fi

# 步骤3: 运行测试
echo ""
echo -e "${YELLOW}🧪 步骤3: 运行测试${NC}"
if make test; then
    echo -e "${GREEN}✅ 测试通过${NC}"
else
    echo -e "${RED}❌ 测试失败${NC}"
    exit 1
fi

# 步骤4: 构建二进制文件
echo ""
echo -e "${YELLOW}🔨 步骤4: 构建二进制文件${NC}"
if make build; then
    echo -e "${GREEN}✅ 构建成功${NC}"
else
    echo -e "${RED}❌ 构建失败${NC}"
    exit 1
fi

# 步骤5: 集成测试
echo ""
echo -e "${YELLOW}🧪 步骤5: 集成测试${NC}"
if ./scripts/integration-test.sh; then
    echo -e "${GREEN}✅ 集成测试通过${NC}"
else
    echo -e "${RED}❌ 集成测试失败${NC}"
    exit 1
fi

# 步骤6: 多平台构建测试
echo ""
echo -e "${YELLOW}🌍 步骤6: 多平台构建测试${NC}"
if make build-all; then
    echo -e "${GREEN}✅ 多平台构建成功${NC}"
    
    # 显示构建的文件
    echo ""
    echo "📦 构建的二进制文件:"
    ls -la build/
else
    echo -e "${RED}❌ 多平台构建失败${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 所有 CI 检查通过！${NC}"
echo "================================"
echo ""
echo "📋 CI 检查摘要:"
echo "  ✅ 代码格式检查"
echo "  ✅ 代码静态分析"
echo "  ✅ 单元测试"
echo "  ✅ 二进制构建"
echo "  ✅ 集成测试"
echo "  ✅ 多平台构建"
echo ""
echo -e "${BLUE}🚀 项目已准备好进行 CI/CD 部署！${NC}"