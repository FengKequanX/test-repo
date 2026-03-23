# 网络设施智能巡检系统 - 完整部署和配置说明

> **文档版本**: 2.0  
> **更新日期**: 2026-03-23  
> **适用平台**: 宇树Go2 EDU + NVIDIA Jetson Orin  
> **ROS版本**: ROS2 Foxy

---

## 📋 目录

1. [环境要求](#1-环境要求)
2. [软件安装](#2-软件安装)
3. [代码部署](#3-代码部署)
4. [模型配置](#4-模型配置)
5. [TensorRT转换](#5-tensorrt转换-推荐)
6. [系统编译](#6-系统编译)
7. [系统启动](#7-系统启动)
8. [参数配置](#8-参数配置)
9. [故障排除](#9-故障排除)

---

## 1. 环境要求

### 1.1 硬件要求

| 组件 | 最低要求 | 推荐配置 |
|------|---------|---------|
| 机器人 | 宇树Go2 EDU | 宇树Go2 EDU + Jetson Orin |
| 计算模块 | NVIDIA Jetson Nano | NVIDIA Jetson Orin NX/AGX |
| 内存 | 4GB | 8GB+ |
| 存储 | 32GB | 64GB+ |
| 相机 | Intel RealSense D435 | Intel RealSense D435i |

### 1.2 软件环境

**操作系统**:
- Ubuntu 20.04 LTS (Jetson)
- JetPack 5.x (已预装CUDA、cuDNN、TensorRT)

**核心软件**:
- ROS2 Foxy Fitzroy
- Python 3.8+
- PyTorch (Jetson专用版本)
- Ultralytics YOLO
- NVIDIA TensorRT

---

## 2. 软件安装

### 2.1 更新系统

```bash
sudo apt update
sudo apt upgrade -y
```

### 2.2 安装Python依赖

```bash
# 安装pip3
sudo apt install -y python3-pip python3-venv

# 升级pip
pip3 install --upgrade pip

# 安装ultralytics
pip3 install ultralytics

# 安装其他依赖
pip3 install flask flask-cors opencv-python numpy
```

### 2.3 安装ROS2依赖包

```bash
# 安装cv_bridge和视觉消息
sudo apt install -y ros-foxy-cv-bridge ros-foxy-vision-msgs ros-foxy-image-transport

# 安装相机驱动
sudo apt install -y ros-foxy-realsense2-camera

# 安装TF2相关
sudo apt install -y ros-foxy-tf2 ros-foxy-tf2-ros
```

### 2.4 验证安装

```bash
# 检查ROS2
ros2 --version

# 检查Python包
python3 -c "from ultralytics import YOLO; print('✅ ultralytics OK')"
python3 -c "import torch; print(f'✅ PyTorch {torch.__version__}')"
python3 -c "import cv2; print(f'✅ OpenCV {cv2.__version__}')"

# 检查TensorRT
ls /usr/src/tensorrt/bin/trtexec
```

---

## 3. 代码部署

### 3.1 创建工作目录

```bash
mkdir -p ~/inspection_system/src
cd ~/inspection_system/src
```

### 3.2 克隆代码仓库

```bash
git clone https://github.com/Ffeng888/test-repo.git
```

### 3.3 复制代码到工作空间

```bash
cp -r test-repo/inspection_system/src/* .
ls -la  # 应该看到4个包
```

### 3.4 目录结构说明

```
~/inspection_system/
├── src/
│   ├── inspection_bringup/      # 启动文件和配置
│   ├── inspection_perception/   # YOLO检测节点
│   ├── inspection_mapping/      # 坐标映射节点
│   └── inspection_viz/          # Web可视化节点
├── models/                      # 模型文件存放（稍后创建）
└── scripts/                     # 工具脚本
    └── convert_to_tensorrt.py   # TensorRT转换脚本
```

---

## 4. 模型配置

### 4.1 创建模型目录

```bash
mkdir -p ~/inspection_system/models
```

### 4.2 复制训练好的模型

**从Windows复制到Jetson:**

```powershell
# Windows PowerShell
scp "E:\port_segment\runs\segment\switch_port_seg_nano\weights\best.pt" go2@192.168.1.100:~/inspection_system/models/yolo26n-seg.pt
```

**在Jetson上重命名（可选）:**

```bash
cd ~/inspection_system/models
# 如果复制时已经命名为yolo26n-seg.pt，跳过此步骤
mv best.pt yolo26n-seg.pt
```

### 4.3 验证模型

```bash
python3 << 'EOF'
from ultralytics import YOLO
import os

model_path = os.path.expanduser('~/inspection_system/models/yolo26n-seg.pt')
model = YOLO(model_path)

print("✅ 模型加载成功!")
print(f"任务类型: {model.task}")
print(f"检测类别: {model.names}")
print(f"输入尺寸: {model.overrides['imgsz']}")
EOF
```

---

## 5. TensorRT转换（推荐）

TensorRT可以显著提升推理性能，推荐部署时使用。

### 5.1 性能对比

| 格式 | FPS | 延迟 | 显存 |
|------|-----|------|------|
| PyTorch (.pt) | 18-22 | 55ms | 2.1GB |
| **TensorRT FP16** | **30-35** | **32ms** | **1.2GB** |

**提升约60%！** 🚀

### 5.2 一键转换

```bash
# 使用一键脚本
cd ~/inspection_system
./convert_model.sh

# 或者使用Python脚本（带性能测试）
python3 scripts/convert_to_tensorrt.py \
    --model ~/inspection_system/models/yolo26n-seg.pt \
    --benchmark
```

### 5.3 验证转换结果

```bash
ls -lh ~/inspection_system/models/
# 应该看到 yolo26n-seg.pt 和 yolo26n-seg.engine
```

---

## 6. 系统编译

### 6.1 安装rosdep依赖

```bash
cd ~/inspection_system

# 初始化rosdep（如果未初始化）
sudo rosdep init 2>/dev/null || true
rosdep update

# 安装依赖
rosdep install --from-paths src --ignore-src -r -y
```

### 6.2 编译代码

```bash
# 编译所有包
colcon build --symlink-install

# 或者只编译特定包
colcon build --symlink-install --packages-select inspection_perception inspection_viz
```

### 6.3 激活工作空间

```bash
source install/setup.bash

# 添加到.bashrc（方便以后使用）
echo "source ~/inspection_system/install/setup.bash" >> ~/.bashrc
```

---

## 7. 系统启动

### 7.1 启动相机节点

**终端1:**

```bash
# 激活ROS2
source /opt/ros/foxy/setup.bash

# 启动RealSense相机
ros2 launch realsense2_camera rs_launch.py \
    depth_module.profile:=640x480x30 \
    rgb_camera.profile:=640x480x30 \
    align_depth.enable:=true
```

### 7.2 启动YOLO检测节点

**终端2:**

```bash
# 激活ROS2和工作空间
source /opt/ros/foxy/setup.bash
source ~/inspection_system/install/setup.bash

# 使用TensorRT模型启动（推荐，性能更好）
ros2 launch inspection_perception perception.launch.py \
    model_path:=~/inspection_system/models/yolo26n-seg.engine
```

### 7.3 启动Web可视化

**终端3:**

```bash
# 激活ROS2和工作空间
source /opt/ros/foxy/setup.bash
source ~/inspection_system/install/setup.bash

# 启动Web服务器
ros2 launch inspection_viz web_server.launch.py
```

### 7.4 查看可视化界面

在Windows浏览器中访问:
```
http://<Jetson_IP>:5000
```

---

## 8. 参数配置

### 8.1 YOLO检测节点参数

| 参数 | 默认值 | 说明 | 推荐值 |
|------|--------|------|--------|
| model_path | yolo26n-seg.pt | 模型文件路径 | 根据实际路径 |
| confidence_threshold | 0.5 | 置信度阈值 | 0.3-0.7 |
| iou_threshold | 0.45 | IoU阈值 | 0.3-0.5 |
| inference_size | 640 | 输入尺寸 | 320/480/640 |
| device | cuda | 计算设备 | cuda/cpu |

**修改参数示例:**

```bash
# 降低置信度阈值（检测更多目标）
ros2 launch inspection_perception perception.launch.py \
    model_path:=~/models/yolo26n-seg.engine \
    confidence_threshold:=0.3
```

### 8.2 Web服务器参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| host | 0.0.0.0 | 监听地址 |
| port | 5000 | 端口号 |
| debug | false | 调试模式 |

---

## 9. 故障排除

### 9.1 编译错误

**错误**: `Package 'cv_bridge' not found`
```bash
sudo apt install ros-foxy-cv-bridge
```

### 9.2 运行时错误

**错误**: `No RealSense devices were found!`
- 检查USB连接: `lsusb | grep Intel`
- 检查权限: `sudo usermod -aG video $USER`

**错误**: `CUDA out of memory`
- 减小输入尺寸: `inference_size:=320`
- 重启Jetson

### 9.3 性能问题

**FPS太低:**
1. 使用TensorRT模型
2. 降低输入分辨率
3. 使用jtop监控资源: `sudo pip3 install jetson-stats && jtop`

---

## 📚 参考文档

- [TENSORRT_GUIDE.md](../TENSORRT_GUIDE.md) - TensorRT完整教程
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - 故障排除
- [QUICK_START.md](../QUICK_START.md) - 快速开始

---

**祝部署顺利！** 🚀
