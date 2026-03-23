#!/bin/bash
# 网络设施智能巡检系统 - 完整部署脚本（含TensorRT转换）
# 用法: ./deploy.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  网络设施智能巡检系统 - 部署脚本${NC}"
echo -e "${GREEN}  含TensorRT自动转换${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查是否提供了模型路径
if [ $# -eq 0 ]; then
    MODEL_PATH="/home/go2/inspection_system/models/yolo26n-seg.pt"
    echo -e "${YELLOW}未指定模型路径，使用默认路径: $MODEL_PATH${NC}"
else
    MODEL_PATH="$1"
    echo -e "${YELLOW}使用指定的模型: $MODEL_PATH${NC}"
fi

# 检查模型文件是否存在
if [ ! -f "$MODEL_PATH" ]; then
    echo -e "${RED}错误: 找不到模型文件: $MODEL_PATH${NC}"
    echo "请提供正确的模型路径，例如:"
    echo "  $0 /home/go2/inspection_system/models/best.pt"
    exit 1
fi

# 获取模型目录和文件名
MODEL_DIR=$(dirname "$MODEL_PATH")
MODEL_NAME=$(basename "$MODEL_PATH" .pt)
ENGINE_PATH="$MODEL_DIR/${MODEL_NAME}.engine"

echo ""
echo -e "${BLUE}📋 部署计划:${NC}"
echo "  1. 检查环境"
echo "  2. 安装依赖"
echo "  3. 下载代码"
echo "  4. 编译工作空间"
echo "  5. 转换为TensorRT"
echo "  6. 验证部署"
echo ""

# ========== 步骤1: 检查环境 ==========
echo -e "${GREEN}[1/6] 检查环境...${NC}"

# 检查是否在Jetson上
if [ -f "/etc/nv_tegra_release" ]; then
    echo -e "${GREEN}✅ 检测到Jetson设备${NC}"
    cat /etc/nv_tegra_release
else
    echo -e "${YELLOW}⚠️ 未检测到Jetson设备，继续部署...${NC}"
fi

# 检查CUDA
if command -v nvcc &> /dev/null; then
    echo -e "${GREEN}✅ CUDA已安装${NC}"
    nvcc --version | grep "release"
else
    echo -e "${YELLOW}⚠️ 未检测到CUDA${NC}"
fi

# 检查ROS2
if [ -d "/opt/ros/foxy" ]; then
    echo -e "${GREEN}✅ ROS2 Foxy已安装${NC}"
else
    echo -e "${RED}❌ 错误: 未检测到ROS2 Foxy${NC}"
    echo "请先安装ROS2 Foxy"
    exit 1
fi

echo ""

# ========== 步骤2: 安装依赖 ==========
echo -e "${GREEN}[2/6] 安装依赖...${NC}"

# 更新软件源
echo "更新软件源..."
sudo apt update -qq

# 安装Python依赖
echo "安装Python依赖..."
pip3 install -q ultralytics flask flask-cors

# 安装ROS2依赖
echo "安装ROS2依赖..."
sudo apt install -y -qq ros-foxy-cv-bridge ros-foxy-vision-msgs

echo -e "${GREEN}✅ 依赖安装完成${NC}"
echo ""

# ========== 步骤3: 下载代码 ==========
echo -e "${GREEN}[3/6] 下载项目代码...${NC}"

# 创建工作目录
mkdir -p ~/inspection_system/src
cd ~/inspection_system/src

# 下载代码
if [ -d "test-repo" ]; then
    echo "代码已存在，更新代码..."
    cd test-repo
    git pull
    cd ..
else
    echo "克隆代码仓库..."
    git clone https://github.com/Ffeng888/test-repo.git
fi

# 复制代码
cp -r test-repo/inspection_system/src/* .

echo -e "${GREEN}✅ 代码下载完成${NC}"
echo ""

# ========== 步骤4: 编译工作空间 ==========
echo -e "${GREEN}[4/6] 编译工作空间...${NC}"

cd ~/inspection_system

# 安装ROS依赖
echo "安装ROS依赖..."
rosdep install --from-paths src --ignore-src -r -y --quiet || true

# 编译
echo "编译代码..."
colcon build --symlink-install --packages-select inspection_perception inspection_viz

# 激活工作空间
source install/setup.bash

echo -e "${GREEN}✅ 编译完成${NC}"
echo ""

# ========== 步骤5: 转换为TensorRT ==========
echo -e "${GREEN}[5/6] 转换为TensorRT...${NC}"

# 复制模型到目标目录
mkdir -p ~/inspection_system/models
cp "$MODEL_PATH" ~/inspection_system/models/

# 运行TensorRT转换
if [ -f "~/inspection_system/scripts/convert_to_tensorrt.py" ]; then
    echo "使用Python脚本转换..."
    python3 ~/inspection_system/scripts/convert_to_tensorrt.py \
        --model ~/inspection_system/models/$(basename "$MODEL_PATH") \
        --output "$ENGINE_PATH"
else
    echo "使用ultralytics直接转换..."
    python3 << EOF
from ultralytics import YOLO
model = YOLO('~/inspection_system/models/$(basename "$MODEL_PATH")')
model.export(format='engine', half=True)
EOF
fi

# 检查转换结果
if [ -f "$ENGINE_PATH" ]; then
    echo -e "${GREEN}✅ TensorRT转换成功!${NC}"
    ls -lh "$ENGINE_PATH"
else
    echo -e "${YELLOW}⚠️ TensorRT转换可能失败，将使用PyTorch模型${NC}"
    ENGINE_PATH="$MODEL_PATH"
fi

echo ""

# ========== 步骤6: 验证部署 ==========
echo -e "${GREEN}[6/6] 验证部署...${NC}"

# 测试模型加载
echo "测试模型加载..."
python3 << EOF
from ultralytics import YOLO
import os

model_path = os.path.expanduser('$ENGINE_PATH')
try:
    model = YOLO(model_path)
    print(f"✅ 模型加载成功: {model_path}")
    print(f"   任务类型: {model.task}")
    print(f"   检测类别: {model.names}")
except Exception as e:
    print(f"❌ 模型加载失败: {e}")
    exit(1)
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  🎉 部署完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📁 模型文件:${NC}"
echo "  PyTorch: $MODEL_PATH"
echo "  TensorRT: $ENGINE_PATH"
echo ""
echo -e "${BLUE}🚀 启动系统:${NC}"
echo "  1. 启动相机:"
echo "     ros2 launch realsense2_camera rs_launch.py"
echo ""
echo "  2. 启动检测:"
echo "     ros2 launch inspection_perception perception.launch.py model_path:=$ENGINE_PATH"
echo ""
echo "  3. 启动Web界面:"
echo "     ros2 launch inspection_viz web_server.launch.py"
echo ""
echo -e "${BLUE}🌐 访问界面:${NC}"
echo "  http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo -e "${YELLOW}💡 提示: 也可以使用一键启动脚本:${NC}"
echo "  ./start_inspection.sh"
echo ""
