#!/usr/bin/env bash
set -e

image_tag=${1:-main}
docker pull ghcr.io/skymule-ai/mullet-ros2-base:${image_tag}
