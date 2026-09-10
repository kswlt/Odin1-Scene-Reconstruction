#!/usr/bin/env python3
"""Publish a bounded, voxelized global preview from Odin's live SLAM cloud."""

from threading import Lock

import numpy as np
import rclpy
from rclpy.duration import Duration
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy
from rclpy.time import Time
from sensor_msgs.msg import PointCloud2, PointField
from sensor_msgs_py import point_cloud2
from std_msgs.msg import Header
from tf2_ros import Buffer, TransformException, TransformListener


def rotation_matrix(q):
    """Return a 3x3 matrix for a geometry_msgs Quaternion."""
    x, y, z, w = q.x, q.y, q.z, q.w
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ], dtype=np.float32)


class MapPreview(Node):
    def __init__(self):
        super().__init__('map_preview')
        self.declare_parameter('input_topic', '/odin1/cloud_slam')
        self.declare_parameter('output_topic', '/odin1/map_preview')
        self.declare_parameter('target_frame', 'odom')
        self.declare_parameter('voxel_size', 0.08)
        self.declare_parameter('max_points', 250000)
        self.declare_parameter('max_input_points', 60000)
        self.declare_parameter('publish_period', 0.5)

        self.input_topic = self.get_parameter('input_topic').value
        self.target_frame = self.get_parameter('target_frame').value
        self.voxel_size = float(self.get_parameter('voxel_size').value)
        self.max_points = int(self.get_parameter('max_points').value)
        self.max_input_points = int(self.get_parameter('max_input_points').value)
        period = float(self.get_parameter('publish_period').value)

        qos = QoSProfile(depth=1, reliability=ReliabilityPolicy.BEST_EFFORT)
        self.publisher = self.create_publisher(
            PointCloud2, self.get_parameter('output_topic').value, qos)
        self.subscription = self.create_subscription(
            PointCloud2, self.input_topic, self.cloud_callback, qos)
        self.tf_buffer = Buffer()
        self.tf_listener = TransformListener(self.tf_buffer, self)
        self.voxels = {}
        self.lock = Lock()
        self.dirty = False
        self.last_tf_warning_ns = 0
        self.last_quality_report_ns = 0
        self.timer = self.create_timer(period, self.publish_preview)
        self.get_logger().info(
            f'Accumulating {self.input_topic} into {self.get_parameter("output_topic").value} '
            f'in frame {self.target_frame} at {self.voxel_size:.3f} m voxels.')

    def cloud_callback(self, msg):
        if not msg.data:
            return
        try:
            rows = point_cloud2.read_points(msg, field_names=('x', 'y', 'z', 'rgb'), skip_nans=True)
            stride = max(1, (msg.width * max(1, msg.height)) // self.max_input_points)
            # Humble returns a structured NumPy array; older ROS releases return
            # an iterator of xyz tuples. Support both forms.
            if isinstance(rows, np.ndarray) and rows.dtype.names:
                rows = rows[::stride]
                points = np.column_stack((
                    rows['x'], rows['y'], rows['z'], rows['rgb'])).astype(np.float32, copy=False)
            else:
                points = [row for index, row in enumerate(rows) if index % stride == 0]
                points = np.asarray(points, dtype=np.float32).reshape((-1, 4)) if points else np.empty((0, 4), dtype=np.float32)
        except (TypeError, ValueError) as exc:
            self.get_logger().warn(f'Unable to read point cloud: {exc}')
            return
        if not len(points):
            return

        xyz = points[:, :3]
        if msg.header.frame_id and msg.header.frame_id != self.target_frame:
            try:
                transform = self.tf_buffer.lookup_transform(
                    self.target_frame, msg.header.frame_id, Time(),
                    timeout=Duration(seconds=0.1))
            except TransformException as exc:
                now = self.get_clock().now().nanoseconds
                if now - self.last_tf_warning_ns > 5_000_000_000:
                    self.get_logger().warn(
                        f'Waiting for TF {self.target_frame} <- {msg.header.frame_id}: {exc}')
                    self.last_tf_warning_ns = now
                return
            xyz = xyz @ rotation_matrix(transform.transform.rotation).T
            translation = transform.transform.translation
            xyz += np.array([translation.x, translation.y, translation.z], dtype=np.float32)
            points[:, :3] = xyz

        cells = np.floor(xyz / self.voxel_size).astype(np.int32)
        with self.lock:
            for cell, point in zip(cells, points):
                key = (int(cell[0]), int(cell[1]), int(cell[2]))
                if key in self.voxels or len(self.voxels) < self.max_points:
                    self.voxels[key] = point
            self.dirty = True
            voxel_count = len(self.voxels)
        now = self.get_clock().now().nanoseconds
        if now - self.last_quality_report_ns > 5_000_000_000:
            self.last_quality_report_ns = now
            quality = 'LOW' if voxel_count < 500 else ('MEDIUM' if voxel_count < 5000 else 'GOOD')
            self.get_logger().info(
                f'SCAN_QUALITY={quality} accumulated_voxels={voxel_count} '
                f'latest_points={len(points)}; move slowly to increase coverage.')

    def publish_preview(self):
        with self.lock:
            if not self.dirty:
                return
            points = np.asarray(list(self.voxels.values()), dtype=np.float32)
            self.dirty = False
        header = Header()
        header.stamp = self.get_clock().now().to_msg()
        header.frame_id = self.target_frame
        fields = [
            PointField(name='x', offset=0, datatype=PointField.FLOAT32, count=1),
            PointField(name='y', offset=4, datatype=PointField.FLOAT32, count=1),
            PointField(name='z', offset=8, datatype=PointField.FLOAT32, count=1),
            PointField(name='rgb', offset=12, datatype=PointField.FLOAT32, count=1),
        ]
        self.publisher.publish(point_cloud2.create_cloud(header, fields, points))


def main():
    rclpy.init()
    node = MapPreview()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
