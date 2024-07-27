# tests/test_node.py

import unittest
from unittest.mock import MagicMock, patch
from yolo_ros.node import YoloROS
import rclpy
from sensor_msgs.msg import Image, PointCloud2
from detection_msgs.msg import Detections
from cv_bridge import CvBridge
from ultralytics import YOLO

class TestYoloROS(unittest.TestCase):

    def setUp(self):
        # Initialize the ROS client library
        rclpy.init()

        # Create a YoloROS instance
        self.node = YoloROS()

        # Mock the YOLO model
        self.node.model = MagicMock(spec=YOLO)
        self.node.model.predict = MagicMock(return_value=[
            MagicMock(boxes=MagicMock(xywh=[[10, 20, 30, 40]], cls=[1], conf=[0.9]), names=MagicMock(get=lambda i: "class_" + str(i)))
        ])

        # Mock CvBridge
        self.node.bridge = MagicMock(spec=CvBridge)
        self.node.bridge.imgmsg_to_cv2 = MagicMock(return_value='fake_image')
        self.node.bridge.cv2_to_imgmsg = MagicMock(return_value='fake_img_msg')

    def test_initialization(self):
        """Test the initialization of YoloROS."""
        self.assertEqual(self.node.yolo_model, "yolov8n.pt")
        self.assertEqual(self.node.input_rgb_topic, "/camera/color/image_raw")
        self.assertEqual(self.node.input_depth_topic, "/camera/depth/points")
        self.assertFalse(self.node.subscribe_depth)
        self.assertFalse(self.node.publish_annotated_image)
        self.assertEqual(self.node.annotated_topic, "/yolo_ros/annotated_image")
        self.assertEqual(self.node.detailed_topic, "/yolo_ros/detection_result")
        self.assertEqual(self.node.threshold, 0.25)
        self.assertEqual(self.node.device, "cpu")

    @patch('rclpy.node.Node.create_subscription')
    def test_image_callback(self, mock_create_subscription):
        """Test the image_callback method."""
        # Create a mock Image message
        mock_image_msg = MagicMock(spec=Image)
        self.node.image_callback(mock_image_msg)

        # Check if the model's predict method was called
        self.node.model.predict.assert_called_with(
            source='fake_image',
            conf=self.node.threshold,
            device=self.node.device,
            verbose=False
        )

        # Check if the detection message was published
        self.assertTrue(self.node.publisher_results.publish.called)

    @patch('rclpy.node.Node.create_subscription')
    def test_sync_callback(self, mock_create_subscription):
        """Test the sync_callback method."""
        # Create mock messages
        mock_rgb_msg = MagicMock(spec=Image)
        mock_depth_msg = MagicMock(spec=PointCloud2)
        self.node.sync_callback(mock_rgb_msg, mock_depth_msg)

        # Check if the model's predict method was called
        self.node.model.predict.assert_called_with(
            source='fake_image',
            conf=self.node.threshold,
            device=self.node.device,
            verbose=False
        )

        # Check if the detection message was published
        self.assertTrue(self.node.publisher_results.publish.called)

    def tearDown(self):
        # Shutdown ROS client library
        rclpy.shutdown()

if __name__ == '__main__':
    unittest.main()
