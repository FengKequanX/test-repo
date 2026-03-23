#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Web服务器节点 - 提供HTTP服务和静态文件
用于展示检测结果的可视化界面
"""

import rclpy
from rclpy.node import Node
from flask import Flask, render_template, jsonify, Response
from flask_cors import CORS
import threading
import base64
import cv2
import numpy as np
from sensor_msgs.msg import Image
from vision_msgs.msg import Detection2DArray
from cv_bridge import CvBridge


class WebServerNode(Node):
    """Web服务器ROS节点"""
    
    def __init__(self):
        super().__init__('web_server')
        
        # 声明参数
        self.declare_parameter('host', '0.0.0.0')
        self.declare_parameter('port', 5000)
        self.declare_parameter('debug', False)
        
        # 获取参数
        self.host = self.get_parameter('host').value
        self.port = self.get_parameter('port').value
        self.debug = self.get_parameter('debug').value
        
        # 初始化Flask应用
        self.app = Flask(__name__, 
                        template_folder='../static',
                        static_folder='../static')
        CORS(self.app)
        
        # CV桥接
        self.bridge = CvBridge()
        
        # 存储最新的检测结果和图像
        self.latest_image = None
        self.latest_detections = None
        self.stats = {
            'fps': 0.0,
            'inference_time': 0.0,
            'frame_count': 0
        }
        
        # 创建订阅者
        self.image_sub = self.create_subscription(
            Image,
            '/detections/visualization',
            self.image_callback,
            10
        )
        
        self.detection_sub = self.create_subscription(
            Detection2DArray,
            '/detections',
            self.detection_callback,
            10
        )
        
        # 设置Flask路由
        self.setup_routes()
        
        # 在单独线程中启动Flask服务器
        self.server_thread = threading.Thread(target=self.run_server)
        self.server_thread.daemon = True
        self.server_thread.start()
        
        self.get_logger().info(f'Web服务器已启动: http://{self.host}:{self.port}')
    
    def setup_routes(self):
        """设置Flask路由"""
        
        @self.app.route('/')
        def index():
            return self.app.send_static_file('index.html')
        
        @self.app.route('/api/status')
        def get_status():
            return jsonify({
                'status': 'running',
                'fps': self.stats['fps'],
                'inference_time': self.stats['inference_time'],
                'frame_count': self.stats['frame_count']
            })
        
        @self.app.route('/api/detections')
        def get_detections():
            if self.latest_detections is None:
                return jsonify({'detections': []})
            return jsonify({
                'detections': self.format_detections(self.latest_detections)
            })
        
        @self.app.route('/api/image')
        def get_image():
            if self.latest_image is None:
                return jsonify({'image': None})
            
            # 转换为base64
            _, buffer = cv2.imencode('.jpg', self.latest_image)
            image_base64 = base64.b64encode(buffer).decode('utf-8')
            
            return jsonify({'image': image_base64})
        
        @self.app.route('/video_feed')
        def video_feed():
            return Response(
                self.generate_frames(),
                mimetype='multipart/x-mixed-replace; boundary=frame'
            )
    
    def generate_frames(self):
        """生成视频流帧"""
        while True:
            if self.latest_image is not None:
                _, buffer = cv2.imencode('.jpg', self.latest_image)
                frame = buffer.tobytes()
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
    
    def image_callback(self, msg):
        """接收可视化图像"""
        try:
            self.latest_image = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        except Exception as e:
            self.get_logger().error(f'图像转换错误: {e}')
    
    def detection_callback(self, msg):
        """接收检测结果"""
        self.latest_detections = msg
    
    def format_detections(self, detection_msg):
        """格式化检测结果为JSON"""
        detections = []
        for det in detection_msg.detections:
            # 获取类别和置信度
            if len(det.results) > 0:
                hypothesis = det.results[0].hypothesis
                class_name = hypothesis.class_id
                confidence = hypothesis.score
                
                detections.append({
                    'class': class_name,
                    'confidence': confidence,
                    'x': det.bbox.center.x,
                    'y': det.bbox.center.y,
                    'width': det.bbox.size_x,
                    'height': det.bbox.size_y
                })
        return detections
    
    def run_server(self):
        """运行Flask服务器"""
        self.app.run(
            host=self.host,
            port=self.port,
            debug=self.debug,
            threaded=True,
            use_reloader=False  # 禁用重加载器以避免与ROS2冲突
        )


def main(args=None):
    rclpy.init(args=args)
    
    try:
        node = WebServerNode()
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f'Web服务器错误: {e}')
    finally:
        if 'node' in locals():
            node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
