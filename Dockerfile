# Target platform: Jetson Orin Nano running JetPack 6.2.2 / L4T R36.5.
# The NVIDIA Container Toolkit on the host supplies the Jetson driver stack at
# runtime. CUDA tooling is installed here so downstream ROS images can compile
# and run CUDA-enabled packages.
FROM ros:humble-ros-base-jammy

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
ARG CUDA_VERSION=12.6
ARG UXRCE_AGENT_VERSION=v2.4.2

ENV CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# CUDA 12.6 is the CUDA version shipped with JetPack 6.2.2.  Use NVIDIA's
# ARM64 Ubuntu 22.04 repository; do not install a CUDA driver in the image.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gpg && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/arm64/cuda-keyring_1.1-1_all.deb \
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
    rm -rf /var/lib/apt/lists/*

# The official ROS image already initialises rosdep. Updating its database here
# makes dependency resolution reproducible at image-build time.
RUN rosdep update

# Micro XRCE-DDS Agent
WORKDIR /opt
COPY patches/CMakeLists.txt /opt/Micro-XRCE-DDS-Agent-CMakeLists.txt

RUN git clone --depth 1 --branch ${UXRCE_AGENT_VERSION} \
      https://github.com/eProsima/Micro-XRCE-DDS-Agent.git && \
    cd Micro-XRCE-DDS-Agent && \
    cp /opt/Micro-XRCE-DDS-Agent-CMakeLists.txt CMakeLists.txt && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --parallel "$(nproc)" && \
    cmake --install build && \
    ldconfig && \
    cd /opt && \
    rm -rf Micro-XRCE-DDS-Agent Micro-XRCE-DDS-Agent-CMakeLists.txt

# PX4 ROS workspace
WORKDIR /opt/ros2_base_ws
COPY repos/ros2.repos ros2.repos

RUN mkdir -p src && \
    vcs import src < ros2.repos && \
    source /opt/ros/humble/setup.bash && \
    rosdep install --from-paths src --ignore-src -r -y && \
    colcon build --merge-install

# tests
RUN /opt/ros2_base_ws/source/install/setup.bash && \
    ros2 pkg prefix px4_msgs && \
    MicroXRCEAgent --help > /dev/null

COPY scripts/entrypoint.sh /usr/local/bin/mullet-ros-entrypoint
COPY scripts/smoke-test.sh tests/cuda_smoke.cu /usr/local/share/mullet-ros/
RUN chmod 0755 /usr/local/bin/mullet-ros-entrypoint \
    /usr/local/share/mullet-ros/smoke-test.sh

ENTRYPOINT ["/usr/local/bin/mullet-ros-entrypoint"]
CMD ["bash"]
