#!/bin/bash
# this script mimics the ROS pipeline behavior
set -e
# ROS version to compile packages, change to melodic if needed
ROS_DISTRO="noetic"

# pipeline behaviour
ROS_BUILDTOOLS_DOCKER_IMAGE="registry.cloud.mov.ai/qa/ros-buildtools-${ROS_DISTRO}:v2.0.18"
# making sure its in the working directory despite where its being called from.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

IN_CONTAINER_MOUNT_POINT="/__w/workspace/src"

container_id=$(docker run -td -v "$(pwd)":$IN_CONTAINER_MOUNT_POINT "$ROS_BUILDTOOLS_DOCKER_IMAGE" sh)
echo "running in $container_id"
docker exec -t "$container_id" bash -c "\
set -e
sudo apt update

export MOVAI_OUTPUT_DIR=/__w/workspace/src/packages
cd $IN_CONTAINER_MOUNT_POINT

# mkdir -p build
cd build
cmake .. && make -j
make install
cd ..
ls -la debian
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -b 2>&1 | tee build.log 
mkdir -p packages
cp ../*.deb $IN_CONTAINER_MOUNT_POINT/packages


" || true

echo "deleting container: $container_id"
docker rm -f "$container_id"

