#!/usr/bin/env bash
set -euo pipefail

image_tag=${1:?usage: scripts/test-on-orin.sh <image-tag>}

MULLET_ROS_IMAGE_TAG="$image_tag" docker compose pull ros2-base
MULLET_ROS_IMAGE_TAG="$image_tag" docker compose run --rm ros2-base \
  /usr/local/share/mullet-ros/smoke-test.sh
