# 网络设施智能巡检系统 - 新手部署完全指南

> 🎯 **本指南目标**：让完全没有ROS2和机器狗开发经验的用户，也能在30分钟内完成系统部署。

---

## 📋 你需要准备什么？

### ✅ 硬件要求
- 宇树Go2 EDU机器狗（已开机并联网）
- RealSense D435i相机（已连接到机器狗）
- Windows电脑（用于SSH连接和查看界面）
- 训练好的YOLOv26n模型文件（best.pt）

### ✅ 软件要求
- Windows PowerShell 或 Git Bash
- 机器狗的IP地址（通过`hostname -I`查看）
- SSH客户端（Windows 10自带）

### ✅ 知识准备
- **不需要**ROS2基础！
- **不需要**机器狗开发经验！
- 只需要能复制粘贴命令即可！

---

## 🚀 快速开始（5步法）

### 第1步：连接机器狗（5分钟）

**在Windows电脑上：**

1. 按 `Win + X`，选择 **Windows PowerShell**
2. 输入：
   ```powershell
   ssh go2@192.168.1.100
   ```
   （把IP换成你的机器狗实际IP）
3. 输入密码登录
4. 看到 `go2@go2-desktop:~$` 就表示成功了！

---

### 第2步：一键安装依赖（10分钟）

**在机器狗上执行这些命令：**

```bash
# 1. 更新软件列表
sudo apt update

# 2. 安装YOLOv26n需要的库
pip3 install ultralytics -i https://pypi.tuna.tsinghua.edu.cn/simple

# 3. 安装Web界面需要的库
pip3 install flask flask-cors -i https://pypi.tuna.tsinghua.edu.cn/simple

# 4. 验证安装
python3 -c "from ultralytics import YOLO; print('✅ YOLOv26n库安装成功！')"
```

如果看到"✅ YOLOv26n库安装成功！"，就可以继续下一步！

---

### 第3步：部署代码和模型（10分钟）

**还是在机器狗上：**

```bash
# 1. 创建工作目录
mkdir -p ~/inspection_system/src
cd ~/inspection_system/src

# 2. 下载代码
git clone https://github.com/Ffeng888/test-repo.git
cp -r test-repo/inspection_system/src/* .

# 3. 创建模型目录
mkdir -p ~/inspection_system/models
```

**然后在Windows电脑上复制模型：**

打开新的PowerShell窗口：
```powershell
scp "E:\port_segment\runs\segment\switch_port_seg_nano\weights\best.pt" go2@192.168.1.100:~/inspection_system/models/yolo26n-seg.pt
```

---

### 第4步：编译代码（5分钟）

**回到机器狗的SSH窗口：**

```bash
cd ~/inspection_system

# 编译（这可能需要几分钟）
colcon build --symlink-install

# 激活工作空间
source install/setup.bash
```

💡 **编译成功后**，你会看到很多绿色的 `[100%]` 提示。

---

### 第5步：启动系统（5分钟）

**你需要打开3个SSH窗口！**

#### 窗口1：启动相机
```bash
source /opt/ros/foxy/setup.bash
ros2 launch realsense2_camera rs_launch.py depth_module.profile:=640x480x30 rgb_camera.profile:=640x480x30 align_depth.enable:=true
```

#### 窗口2：启动YOLO检测
```bash
source /opt/ros/foxy/setup.bash
source ~/inspection_system/install/setup.bash
ros2 launch inspection_perception perception.launch.py
```

#### 窗口3：启动Web界面
```bash
source /opt/ros/foxy/setup.bash
source ~/inspection_system/install/setup.bash
ros2 launch inspection_viz web_server.launch.py
```

---

## 🎉 查看结果

在你的Windows电脑上：

1. 打开浏览器
2. 访问：`http://<机器狗IP>:5000`
3. 你应该能看到实时检测画面！

---

## 🐛 遇到问题？

### 问题1：找不到命令
**解决**：
```bash
# 确保ROS2已安装
ls /opt/ros/foxy/

# 如果没有，需要安装ROS2 Foxy
```

### 问题2：模型加载失败
**解决**：
```bash
# 检查模型是否存在
ls -lh ~/inspection_system/models/

# 应该看到 yolo26n-seg.pt 文件，大小几MB到几十MB
```

### 问题3：Web界面打不开
**解决**：
```bash
# 检查防火墙
sudo ufw allow 5000

# 检查服务是否运行
ros2 node list | grep web
```

---

## 📖 下一步

系统运行后，你可以：
1. **录制演示视频** - 用于中期检查
2. **查看检测统计** - 在Web界面看到交换机/网口计数
3. **导出巡检报告** - 点击"导出报告"按钮

---

## 💡 常用命令

| 操作 | 命令 |
|------|------|
| 连接机器狗 | `ssh go2@192.168.1.100` |
| 查看IP | `hostname -I` |
| 查看ROS话题 | `ros2 topic list` |
| 查看运行节点 | `ros2 node list` |
| 停止所有 | 按 `Ctrl + C` |

---

**祝你部署顺利！有问题随时提问！** 🚀
