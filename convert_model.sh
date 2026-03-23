#!/bin/bash
# YOLOv26n一键转换TensorRT脚本
# 用法: ./convert_model.sh [模型路径]

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认模型路径
MODEL_PATH="${1:-/home/go2/inspection_system/models/yolo26n-seg.pt}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  YOLOv26n TensorRT转换工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查模型文件是否存在
if [ ! -f "$MODEL_PATH" ]; then
    echo -e "${RED}错误: 找不到模型文件: $MODEL_PATH${NC}"
    echo "用法: $0 [模型路径]"
    echo "例如: $0 ~/inspection_system/models/best.pt"
    exit 1
fi

echo -e "${YELLOW}📦 模型文件: $MODEL_PATH${NC}"

# 获取模型目录
MODEL_DIR=$(dirname "$MODEL_PATH")
MODEL_NAME=$(basename "$MODEL_PATH" .pt)
ENGINE_PATH="$MODEL_DIR/${MODEL_NAME}.engine"

echo -e "${YELLOW}🎯 输出路径: $ENGINE_PATH${NC}"
echo ""

# 激活Python环境（如果需要）
# source ~/inspection_system/venv/bin/activate  # 如果使用虚拟环境

# 运行转换脚本
python3 $(dirname "$0")/../scripts/convert_to_tensorrt.py \
    --model "$MODEL_PATH" \
    --output "$ENGINE_PATH" \
    --imgsz 640 \
    --workspace 2

# 检查转换结果
if [ -f "$ENGINE_PATH" ]; then
    echo ""
    echo -e "${GREEN}✅ 转换成功!${NC}"
    echo -e "${GREEN}📁 TensorRT引擎: $ENGINE_PATH${NC}"
    
    # 显示文件大小
    SIZE=$(du -h "$ENGINE_PATH" | cut -f1)
    echo -e "${GREEN}📊 文件大小: $SIZE${NC}"
    echo ""
    echo "使用TensorRT引擎启动检测节点:"
    echo "  ros2 launch inspection_perception perception.launch.py model_path:=$ENGINE_PATH"
else
    echo -e "${RED}❌ 转换失败，未找到输出文件${NC}"
    exit 1
fi
