# YOLOv26n模型在宇树Go2上的详细部署指南

> **重要提示**：本指南专为ROS2和机器狗二次开发新手编写，每一步都配有详细说明。

## 📚 目录

1. [准备工作](#1-准备工作)
2. [连接机器狗](#2-连接机器狗)
3. [安装必要软件](#3-安装必要软件)
4. [部署代码到机器狗](#4-部署代码到机器狗)
5. [复制你的YOLOv26n模型](#5-复制你的yolov26n模型)
6. [编译工作空间](#6-编译工作空间)
7. [启动检测系统](#7-启动检测系统)
8. [查看可视化界面](#8-查看可视化界面)
9. [常见问题解决](#9-常见问题解决)

---

## 1. 准备工作

### 1.1 确认硬件连接

在开始之前，请确认：

✅ **机器狗已开机** - Go2背部电源按钮，长按3秒，听到启动音乐  
✅ **你已通过SSH连接到机器狗** - 能正常登录Jetson板卡  
✅ **RealSense D435i相机已连接** - 通过USB-C线连接到Jetson  
✅ **网络连接正常** - 机器狗能上网（用于安装软件）

### 1.2 确认你的模型文件

在Windows电脑上，找到你的训练好的模型：
```
E:\port_segment\runs\segment\switch_port_seg_nano\weights\best.pt
```

这个文件等下要复制到机器狗上。

### 1.3 记住机器狗的IP地址

在机器狗上执行：
```bash
hostname -I
```

你会看到类似：`192.168.1.100` 的IP地址，记下来！

---

## 2. 连接机器狗

### 2.1 Windows上使用PowerShell连接

1. **按 `Win + X`，选择"Windows PowerShell"**

2. **输入SSH连接命令**：
   ```powershell
   ssh go2@192.168.1.100
   ```
   （把IP换成你的机器狗实际IP）

3. **输入密码**：`123` 或者你自己设置的密码

4. **看到欢迎信息就表示连接成功了！** 你会看到类似：
   ```
   Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.10.104-tegra aarch64)
   go2@go2-desktop:~$
   ```

---

## 3. 安装必要软件

现在你在机器狗的命令行中了（提示符是 `go2@go2-desktop:~$`）。

### 3.1 更新软件源

```bash
sudo apt update
```

### 3.2 安装ultralytics库

```bash
pip3 install ultralytics
```

💡 **如果安装很慢**，可以使用国内镜像：
```bash
pip3 install ultralytics -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 3.3 安装Flask（用于Web界面）

```bash
pip3 install flask flask-cors
```

---

## 4. 部署代码到机器狗

### 4.1 创建工作目录

在机器狗上执行：

```bash
mkdir -p ~/inspection_system/src
cd ~/inspection_system/src
```

### 4.2 克隆代码仓库

```bash
git clone https://github.com/Ffeng888/test-repo.git
cp -r test-repo/inspection_system/src/* .
```

---

## 5. 复制你的YOLOv26n模型

在Windows的PowerShell中执行：

```powershell
scp "E:\port_segment\runs\segment\switch_port_seg_nano\weights\best.pt" go2@192.168.1.100:~/inspection_system/models/yolo26n-seg.pt
```

---

## 6. 编译工作空间

```bash
cd ~/inspection_system
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
```

---

## 7. 启动检测系统

### 7.1 启动相机节点（终端1）

```bash
source /opt/ros/foxy/setup.bash
ros2 launch realsense2_camera rs_launch.py depth_module.profile:=640x480x30 rgb_camera.profile:=640x480x30 align_depth.enable:=true
```

### 7.2 启动YOLO检测节点（终端2）

```bash
source /opt/ros/foxy/setup.bash
source ~/inspection_system/install/setup.bash
ros2 launch inspection_perception perception.launch.py
```

### 7.3 启动Web服务器（终端3）

```bash
source /opt/ros/foxy/setup.bash
source ~/inspection_system/install/setup.bash
ros2 launch inspection_viz web_server.launch.py
```

---

## 8. 查看可视化界面

在浏览器中访问：
```
http://<机器狗IP>:5000
```

例如：`http://192.168.1.100:5000`

---

## 9. 常见问题解决

详见完整部署指南：docs/setup_guide_detailed.md

---

## 📞 技术支持

如有问题，请查看详细文档或联系项目维护者。
