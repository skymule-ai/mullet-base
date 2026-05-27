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
# 4. Workspace setup
# -----------------------------
WORKDIR /opt/ros2_base_ws

COPY repos/ros2.repos /opt/ros2_base_ws/ros2.repos

RUN mkdir -p /opt/ros2_base_ws/src && \
    vcs import /opt/ros2_base_ws/src < /opt/ros2_base_ws/ros2.repos

# -----------------------------
# 5. Build workspace
# -----------------------------
RUN source /opt/ros/humble/setup.bash && \
    rosdep install --from-paths /opt/ros2_base_ws/src --ignore-src -r -y && \
    colcon build --merge-install

# -----------------------------
# 6. Environment setup
# -----------------------------
RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc && \
    echo "source /opt/ros2_base_ws/install/setup.bash" >> /etc/bash.bashrc

CMD ["bash"]