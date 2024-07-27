#!/bin/bash
set -e

# Check and source ROS environment
if [ -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then
    echo "Sourcing /opt/ros/$ROS_DISTRO/setup.bash"
    source /opt/ros/$ROS_DISTRO/setup.bash
else
    echo "/opt/ros/$ROS_DISTRO/setup.bash not found"

    if [ -f "/opt/ros/$ROS_DISTRO/install/setup.bash" ]; then
        echo "Sourcing /opt/ros/$ROS_DISTRO/install/setup.bash"
        source /opt/ros/$ROS_DISTRO/install/setup.bash
    else
        echo "/opt/ros/$ROS_DISTRO/install/setup.bash not found"
        echo "Please ensure ROS is installed correctly."
        exit 1
    fi
fi

# Check and source workspace setup
if [ -f "$WORKSPACE_ROOT/install/setup.bash" ]; then
    echo "Sourcing $WORKSPACE_ROOT/install/setup.bash"
    source "$WORKSPACE_ROOT/install/setup.bash"
else
    echo "$WORKSPACE_ROOT/install/setup.bash not found"
    echo "Please ensure the workspace has been built correctly."
    exit 1
fi

# Execute any passed command
exec "$@"
