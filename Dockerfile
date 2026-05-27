FROM dustynv/ros:humble-ros-base-l4t-r36.3.0

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    python3-colcon-common-extensions \
    vim \
  && rm -rf /var/lib/apt/lists/*

RUN if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
    rosdep init; \
  fi \
  && rosdep update

WORKDIR /opt/ros2_base_ws

COPY repos/ros2.repos /opt/ros2_base_ws/ros2.repos

RUN mkdir -p /opt/ros2_base_ws/src \
  && vcs import /opt/ros2_base_ws/src < /opt/ros2_base_ws/ros2.repos

RUN source /opt/ros/humble/setup.bash \
  && rosdep install --from-paths /opt/ros2_base_ws/src --ignore-src -r -y \
  && colcon build --merge-install

RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc \
  && echo "source /opt/ros2_base_ws/install/setup.bash" >> /etc/bash.bashrc

CMD ["bash"]
