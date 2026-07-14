# 🚀 mullet_ros_base

Developer-friendly ARM64 ROS 2 Humble base image for NVIDIA Jetson devices, designed for PX4, MAVLink, CUDA-enabled robotics, and downstream sensor drivers.

## Platform target

This repository currently targets one platform:

| Component | Version |
| --- | --- |
| Hardware | NVIDIA Jetson Orin Nano |
| JetPack | 6.2.2 |
| Jetson Linux / L4T | R36.5.0 |
| Ubuntu | 22.04 |
| ROS 2 | Humble |
| CUDA toolkit | 12.6 |

The Jetson host must have the NVIDIA Container Toolkit configured. The container uses the host driver stack and includes CUDA development tooling for downstream packages.

This image provides a ready-to-use ROS 2 environment with the PX4 ROS message interfaces and Micro XRCE-DDS Agent already installed, reducing setup time and ensuring reproducible deployments across development machines and robots.

---

## ✨ Features

- 🤖 ROS 2 Humble for ARM64
- 🚁 Prebuilt PX4 ROS message interfaces (`px4_msgs`)
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

---

## 📥 Pull on Jetson

```bash
MULLET_ROS_IMAGE_TAG=main docker compose pull ros2-base
MULLET_ROS_IMAGE_TAG=main docker compose run --rm ros2-base
```

For a released image, set `MULLET_ROS_IMAGE_TAG` to an immutable Git tag such as `v0.1.0` (for example, update `.env` or run `export MULLET_ROS_IMAGE_TAG=v0.1.0`).

## Test a CI image on the Orin

Every push to GitHub publishes an immutable image tag in the form `sha-<short-commit-sha>`.
After the workflow succeeds, use that tag on the Jetson without rebuilding locally:

```bash
git clone git@github.com:skymule-ai/mullet_ros_base.git
cd mullet_ros_base
cp .env.example .env
./scripts/test-on-orin.sh sha-<short-commit-sha>
```

The smoke test validates ROS/PX4 package availability, Micro XRCE-DDS Agent, CUDA compilation, and CUDA device visibility. The Jetson needs permission to pull the GHCR package: use `docker login ghcr.io` with a GitHub token that has `read:packages` if the package is private.

## Development and release workflow

1. Create a feature branch, for example `feat/r36.5-cuda-base`.
2. Push it to GitHub. CI builds and publishes a test image tagged `sha-<short-commit-sha>`.
3. Run `./scripts/test-on-orin.sh sha-<short-commit-sha>` on an Orin with the target JetPack version.
4. Open a pull request only after the Orin smoke test passes. The pull request runs an ARM64 build but does not publish an image.
5. Merge the pull request into `main`. CI publishes `:main` and a new immutable SHA image.
6. Create and push a Git tag such as `v0.1.0` only for an image that has passed hardware validation. CI publishes the matching `:v0.1.0` image.

`main` is a continuously tested integration image. Deploy drones from an immutable release tag, never from `main`.

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

### 🚁 PX4 ROS message interfaces

Installed from:

```bash
repos/ros2.repos
```

`px4_msgs` follows the PX4 `release/1.17` branch. Update this reference only together with the PX4 firmware message definitions used by the flight controller. Pin a commit SHA here later if strict bit-for-bit rebuild reproducibility becomes necessary.

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
FROM ghcr.io/skymule-ai/mullet-ros2-base:v0.1.0

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
