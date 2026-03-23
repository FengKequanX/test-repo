# 网络设施智能巡检系统

> **版本**: 1.0.0  
> **更新日期**: 2026-03-23  
> **模型支持**: YOLOv26n-seg, YOLOv26s-seg  
> **平台**: 宇树Go2 EDU + NVIDIA Jetson Orin

## 🎯 项目概述

本项目是中国农业大学计算机科学与技术专业本科毕业设计，**专为新手开发者设计**，基于宇树Go2四足机器人、Intel RealSense D435i深度相机和NVIDIA Jetson边缘计算平台，开发一套用于机房网络设施智能化巡检的系统。

### 为什么选择YOLOv26n？

YOLOv26n是Ultralytics在2026年1月发布的最新模型，相比YOLOv8有显著优势：

✅ **无需NMS后处理** - 端到端设计，推理更快  
✅ **边缘设备优化** - CPU速度快43%，非常适合Jetson  
✅ **小目标检测强** - 专门针对小目标优化的损失函数  
✅ **部署友好** - 无需复杂后处理，导出TensorRT更简单

---

## 📦 项目结构

```
inspection_system/
├── src/
│   ├── inspection_perception/   ⭐ YOLOv26n检测节点
│   ├── inspection_viz/          ⭐ Web可视化界面
│   ├── inspection_mapping/      # 坐标映射
│   └── inspection_bringup/      # 启动配置
├── models/                      # 放你的yolo26n-seg.pt模型
├── docs/
│   └── setup_guide.md          # 详细部署指南
└── scripts/                     # 工具脚本
```

---

## 🚀 快速开始（适合新手）

### 方式一：使用一键启动脚本

```bash
# 1. 下载代码
git clone https://github.com/Ffeng888/test-repo.git
cd test-repo/inspection_system

# 2. 复制你的YOLOv26n模型到 models/ 目录
# 模型文件：yolo26n-seg.pt

# 3. 启动系统
chmod +x start_inspection.sh
./start_inspection.sh
```

### 方式二：分步启动（推荐学习）

详见 [QUICK_START.md](QUICK_START.md) - 新手5分钟快速上手指南

### 方式三：详细部署指南

详见 [DEPLOY_YOLOV26N.md](DEPLOY_YOLOV26N.md) - 每一步都有详细说明

---

## 📋 功能特性

### 视觉感知
- ✅ **YOLOv26n实例分割** - 实时检测交换机与未插网口
- ✅ **分割掩码** - 像素级精确边界
- ✅ **TensorRT加速** - Jetson上实时25-30 FPS
- ✅ **自动类别识别** - 从模型中读取类别名称

### 系统架构
- ✅ **ROS2 Foxy** - 标准机器人操作系统
- ✅ **节点解耦** - 感知、融合、可视化分离
- ✅ **标准消息** - vision_msgs/Detection2DArray
- ✅ **参数可配置** - 置信度、IoU阈值可调

### Web可视化
- ✅ **实时画面** - 带检测框和分割mask
- ✅ **统计面板** - 交换机/网口计数、FPS显示
- ✅ **检测历史** - 实时更新的检测列表
- ✅ **报告导出** - 一键导出CSV巡检报告
- ✅ **响应式设计** - 支持手机/平板访问

---

## 💻 系统要求

### 硬件
- **机器人**: 宇树Go2 EDU（配备Jetson Orin）
- **相机**: Intel RealSense D435i
- **计算**: NVIDIA Jetson Orin Nano / NX

### 软件
- **操作系统**: Ubuntu 20.04 (Jetson)
- **ROS版本**: ROS2 Foxy Fitzroy
- **Python**: 3.8+
- **深度学习**: PyTorch + Ultralytics

---

## 📊 性能指标

| 模型 | 输入尺寸 | Jetson Orin FPS | mAP@50 |
|------|---------|----------------|--------|
| yolo26n-seg | 640×640 | 25-30 | > 85% |
| yolo26s-seg | 640×640 | 20-25 | > 88% |

**注**: 实际性能取决于具体环境和优化程度。

---

## 📖 文档列表

- [QUICK_START.md](QUICK_START.md) - 新手5分钟快速上手指南 ⭐推荐先看
- [DEPLOY_YOLOV26N.md](DEPLOY_YOLOV26N.md) - YOLOv26n详细部署指南
- [docs/setup_guide.md](docs/setup_guide.md) - 完整部署和配置说明
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 项目总结和行动计划
- [MIDTERM_CHECKLIST.md](MIDTERM_CHECKLIST.md) - 中期检查准备清单
- [docs/midterm_presentation/PPT_OUTLINE.md](docs/midterm_presentation/PPT_OUTLINE.md) - 17页PPT大纲

---

## 🔧 技术栈

### 深度学习
- **模型**: YOLOv26n-seg (Ultralytics)
- **推理**: PyTorch / TensorRT
- **优势**: NMS-free设计，边缘优化

### 机器人系统
- **框架**: ROS2 Foxy
- **中间件**: DDS (Data Distribution Service)
- **消息**: vision_msgs, sensor_msgs

### 可视化
- **后端**: Flask (Python)
- **前端**: HTML5 + JavaScript
- **实时**: WebSocket / HTTP SSE

---

## 🎯 使用场景

### 机房巡检
- 自动识别网络交换机
- 检测未插网口
- 生成资产清单

### 安全审计
- 发现未登记设备（影子IT）
- 检测非法接入点
- 物理设施状态监控

### 资产管理
- 网络设备物理位置映射
- 动态资产清单生成
- 设备变更追踪

---

## 📞 技术支持

### 常见问题
1. **相机无法启动** - 检查USB连接和权限
2. **模型加载失败** - 检查模型路径和ultralytics版本
3. **Web界面打不开** - 检查防火墙和端口占用

### 获取帮助
- 查看详细文档：[docs/setup_guide.md](docs/setup_guide.md)
- 检查日志：`~/.ros/log/`
- ROS命令：`ros2 topic list`, `ros2 node list`

---

## 📝 更新日志

### v1.0.0 (2026-03-23)
- ✅ 初始版本发布
- ✅ 支持YOLOv26n模型
- ✅ Web可视化界面
- ✅ 详细部署文档

---

## 👥 开发团队

- **作者**: 封科全
- **学号**: 2022308250116
- **学院**: 信息与电气工程学院
- **专业**: 计算机科学与技术
- **指导教师**: 杨丽丽 副教授
- **学校**: 中国农业大学

---

## 📄 许可证

本项目为学术用途，仅供毕业设计使用。

---

## 🙏 致谢

感谢指导教师杨丽丽副教授的悉心指导，感谢中国农业大学信息与电气工程学院的支持。

感谢以下开源项目：
- [Ultralytics YOLO](https://github.com/ultralytics/ultralytics)
- [ROS2](https://docs.ros.org/en/foxy/)
- [RealSense ROS](https://github.com/IntelRealSense/realsense-ros)

---

**祝部署顺利！如有问题，欢迎提交Issue或联系项目维护者。** 🚀
