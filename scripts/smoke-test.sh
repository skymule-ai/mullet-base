#!/usr/bin/env bash
set -euo pipefail

ros2 pkg prefix px4_msgs
MicroXRCEAgent udp4 --help > /dev/null
nvcc --version

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

nvcc -o "$test_dir/cuda-smoke" /usr/local/share/mullet-ros/cuda_smoke.cu
"$test_dir/cuda-smoke"
