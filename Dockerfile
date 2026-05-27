FROM dustynv/ros:humble-ros-base-l4t-r36.3.0

SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

# -----------------------------
# 1. Fix broken ROS apt key (EXPKEYSIG issue)
# -----------------------------
RUN apt-get update || true && \
    apt-get install -y --no-install-recommends \
      curl \
      gnupg \
      ca-certificates

# Replace ROS2 key with current official key
RUN mkdir -p /usr/share/keyrings && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | \
    tee /usr/share/keyrings/ros-archive-keyring.gpg > /dev/null

# Re-add ROS2 repository with correct signing method
RUN rm -f /etc/apt/sources.list.d/ros2*.list || true && \
    echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
    > /etc/apt/sources.list.d/ros2.list

# -----------------------------
# 2. Now safe apt-get install
# -----------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      git \
      python3-pip \
      python3-rosdep \
      python3-vcstool \
      python3-colcon-common-extensions \
      vim && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------
# 3. rosdep setup (safe)
# -----------------------------
RUN if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
      rosdep init; \
    fi && \
    rosdep update

# -----------------------------
# 4. Micro XRCE DDS Agent
# -----------------------------
WORKDIR /opt

COPY patches/micro-xrce-dds-agent.patch /opt/micro-xrce-dds-agent.patch

RUN git clone -b v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git && \
    cd Micro-XRCE-DDS-Agent && \
    git apply /opt/micro-xrce-dds-agent.patch && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd /opt && \
    rm -rf /opt/Micro-XRCE-DDS-Agent /opt/micro-xrce-dds-agent.patch

# -----------------------------
# 5. Workspace setup
# -----------------------------
WORKDIR /opt/ros2_base_ws

COPY repos/ros2.repos /opt/ros2_base_ws/ros2.repos

RUN mkdir -p /opt/ros2_base_ws/src && \
    vcs import /opt/ros2_base_ws/src < /opt/ros2_base_ws/ros2.repos

# -----------------------------
# 6. Build workspace
# -----------------------------
RUN source /opt/ros/humble/install/setup.bash && \
    rosdep install --from-paths /opt/ros2_base_ws/src --ignore-src -r -y && \
    colcon build --merge-install

# -----------------------------
# 7. Environment setup
# -----------------------------
RUN echo "source /opt/ros/humble/install/setup.bash" >> /etc/bash.bashrc && \
    echo "source /opt/ros2_base_ws/install/setup.bash" >> /etc/bash.bashrc

CMD ["bash"]
