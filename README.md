# 🚀 mullet_ros_base

High-performance ARM64 ROS 2 Humble base image for NVIDIA Jetson devices, designed for PX4, MAVLink, and robotics development.

This image provides a ready-to-use ROS 2 environment with prebuilt PX4 ROS packages and Micro XRCE DDS Agent already installed, reducing setup time and ensuring reproducible deployments across development machines and robots.

---

## ✨ Features

- 🤖 ROS 2 Humble for ARM64
- 🚁 Prebuilt PX4 ROS 2 packages
- 📡 Micro XRCE DDS Agent v2.4.2 installed system-wide
- ⚡ Optimized for NVIDIA Jetson platforms
- 🐳 Reproducible Docker-based workflow
- 🧩 Easy downstream extension for project-specific stacks

---

# ⚠️ CRUCIAL: Required Jetson UART setup

Before running the container on a Jetson Orin, you **MUST** configure UART access on the host system.

Without this setup, serial communication with PX4, MAVLink devices, flight controllers, and Micro XRCE DDS may **not work correctly**.

The setup procedure is based on the work from the
[jetson-orin-uart repository](https://github.com/jetsonhacks/jetson-orin-uart).

Run the following commands directly on the Jetson host:

```bash
git clone https://github.com/jetsonhacks/jetson-orin-uart.git
cd jetson-orin-uart
sudo bash install.sh
cd ..
rm -rf jetson-orin-uart
sudo reboot
````

After the reboot, the UART interfaces will be properly configured and accessible from Docker containers.


---

## 🛠️ Build locally

```bash
docker compose build
````

---

## ▶️ Run locally

```bash
docker compose run --rm ros2-base
```

Or launch the full stack in detached mode:

```bash
docker compose up -d
```

---

## 📥 Pull on Jetson

```bash
docker pull ghcr.io/skymule-ai/mullet-ros2-base:latest
docker compose up -d
```

---

## 🔄 Update ROS package sources

Modify the repositories listed in:

```bash
repos/ros2.repos
```

Then rebuild the image:

```bash
docker compose build
```

---

## 📦 Included software

### 🚁 PX4 ROS 2 packages

Installed from:

```bash
repos/ros2.repos
```

This allows version pinning and reproducible builds across robots and CI pipelines.

### 📡 Micro XRCE DDS Agent

* Version: `v2.4.2`
* Installed system-wide
* Built using a patched `CMakeLists.txt` from:

```bash
patches/CMakeLists.txt
```

---

## 🧩 Extending the base image

It is recommended to keep this base image minimal and stable.

For project-specific dependencies, create a downstream image:

```Dockerfile
FROM ghcr.io/skymule-ai/mullet-ros2-base:latest

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      <your-packages> \
  && rm -rf /var/lib/apt/lists/*
```

If additional packages are required globally, add them directly to the base `Dockerfile` and rebuild.

---

## 🎯 Typical use cases

* PX4 offboard control
* MAVROS and MAVLink integrations
* Multi-container robotics stacks
* Jetson-based autonomous drones
* CI/CD robotics pipelines
* ROS 2 development environments

---

## 🏗️ Suggested workflow

1. Keep this repository as the stable ROS foundation layer
2. Build project-specific images on top of it
3. Pin repositories through `.repos` files
4. Use GitHub Actions to automatically build and publish images to GHCR

This keeps deployments reproducible across development PCs, Jetson devices, and CI runners.


