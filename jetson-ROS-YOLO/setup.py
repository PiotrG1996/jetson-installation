import os
from glob import glob
from setuptools import find_packages, setup

package_name = 'yolo_ros'

def read_long_description():
    """Read the long description from the README file."""
    with open('README.md', 'r', encoding='utf-8') as file:
        return file.read()

setup(
    name=package_name,
    version='0.0.1',
    author='Piotr',
    author_email='PiotrGapski96@gmail.com',
    maintainer='Piotr',
    maintainer_email='PiotrGapski96@gmail.com',
    description='A ROS package for YOLO object detection integration.',
    long_description=read_long_description(),
    long_description_content_type='text/markdown',
    license='MIT',
    url='https://github.com/yourusername/yolo_ros',  # Replace with your project's URL
    packages=find_packages(exclude=['tests']),
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'launch'), glob(os.path.join('launch', '*launch.py'))),
        (os.path.join('share', package_name, 'config'), glob(os.path.join('config', '*.yaml'))),
    ],
    install_requires=[
        'setuptools',
        'rclpy',
        'sensor_msgs',
        'detection_msgs',
        'cv_bridge',
        'ultralytics',
    ],
    python_requires='>=3.7',
    classifiers=[
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Software Development :: Libraries',
        'Topic :: System :: Hardware',
    ],
    zip_safe=False,
    tests_require=['pytest'],
    test_suite='tests',
    entry_points={
        'console_scripts': [
            'yolo_ros = yolo_ros.node:main',
        ],
    },
)
