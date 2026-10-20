# Target platform: Jetson Orin Nano running JetPack 6.2.2 / L4T R36.5 (CUDA 12.6 driver).
# The NVIDIA Container Toolkit on the host supplies the Jetson driver stack at
# runtime. CUDA tooling is installed here so downstream ROS images can compile
# and run CUDA-enabled packages.
FROM ros:jazzy-ros-base-noble

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
ARG CUDA_VERSION=13.2
ARG UXRCE_AGENT_VERSION=v2.4.2

# Ubuntu 24.04 has no CUDA 12.6 for this board, so the image carries the CUDA 13
# toolkit plus NVIDIA's cuda-compat-orin user-space driver, which runs CUDA 13 on
# the JetPack 6 kernel driver. Its libraries come first on LD_LIBRARY_PATH.
ENV CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/compat_orin:/usr/local/cuda/lib64

# NVIDIA's Ubuntu 24.04 SBSA repository; no CUDA driver is installed in the image
# (the compat package is unpacked, not installed, so it pulls no driver packages).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gpg && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/sbsa/cuda-keyring_1.1-1_all.deb \
      -o /tmp/cuda-keyring.deb && \
    dpkg -i /tmp/cuda-keyring.deb && \
    rm /tmp/cuda-keyring.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      cuda-toolkit-${CUDA_VERSION/./-} \
      git \
      python3-pip \
      vim && \
    cd /tmp && \
    apt-get download cuda-compat-orin-${CUDA_VERSION/./-} && \
    dpkg-deb -x cuda-compat-orin-*.deb / && \
    rm cuda-compat-orin-*.deb && \
    test -d /usr/local/cuda-${CUDA_VERSION}/compat_orin && \
    rm -rf /var/lib/apt/lists/*

# The official ROS image already initialises rosdep. Updating its database here
# makes dependency resolution reproducible at image-build time.
RUN rosdep update

# PX4 ROS workspace
WORKDIR /opt/ros2_base_ws
COPY repos/ros2.repos ros2.repos

RUN mkdir -p src && \
    vcs import src < ros2.repos && \
    source /opt/ros/${ROS_DISTRO}/setup.bash && \
    apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/* && \
    colcon build --merge-install

# Micro XRCE-DDS Agent
WORKDIR /opt
COPY patches/CMakeLists.txt /opt/Micro-XRCE-DDS-Agent-CMakeLists.txt

RUN git clone --depth 1 --branch ${UXRCE_AGENT_VERSION} \
      https://github.com/eProsima/Micro-XRCE-DDS-Agent.git && \
    cd Micro-XRCE-DDS-Agent && \
    cp /opt/Micro-XRCE-DDS-Agent-CMakeLists.txt CMakeLists.txt && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd /opt && \
    rm -rf Micro-XRCE-DDS-Agent Micro-XRCE-DDS-Agent-CMakeLists.txt

# The agent bundles Fast DDS 2.14.7 built on fastcdr 1. ROS Jazzy ships a file of the same name
# built on fastcdr 2, and the ROS setup puts it first on LD_LIBRARY_PATH: the agent then loads
# ROS's copy and segfaults on the first message. Run it on its own libraries only.
RUN mkdir -p /usr/local/libexec && \
    mv /usr/local/bin/MicroXRCEAgent /usr/local/libexec/MicroXRCEAgent && \
    printf '#!/bin/sh\nLD_LIBRARY_PATH=/usr/local/lib exec /usr/local/libexec/MicroXRCEAgent "$@"\n' \
      > /usr/local/bin/MicroXRCEAgent && \
    chmod +x /usr/local/bin/MicroXRCEAgent

    # tests
RUN source /opt/ros2_base_ws/install/setup.bash && \
    ros2 pkg prefix px4_msgs
RUN MicroXRCEAgent udp4 --help > /dev/null

COPY scripts/setup.bash /usr/local/share/mullet-ros/setup.bash
COPY scripts/profile.sh /etc/profile.d/00-mullet-ros.sh
COPY scripts/entrypoint.sh /usr/local/bin/mullet-ros-entrypoint
COPY scripts/smoke-test.sh tests/cuda_smoke.cu /usr/local/share/mullet-ros/
RUN chmod 0755 /usr/local/share/mullet-ros/setup.bash \
    /usr/local/bin/mullet-ros-entrypoint \
    /usr/local/share/mullet-ros/smoke-test.sh

ENTRYPOINT ["/usr/local/bin/mullet-ros-entrypoint"]
CMD ["bash"]
