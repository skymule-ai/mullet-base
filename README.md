# mullet-base

Developer-friendly ARM64 ROS 2 Jazzy base image for NVIDIA Jetson devices, designed for PX4, MAVLink, CUDA-enabled robotics, and downstream sensor drivers.

## Platform target

This repository currently targets one platform:

| Component | Version |
| --- | --- |
| Hardware | NVIDIA Jetson Orin Nano |
| JetPack (host) | 6.2.2 |
| Jetson Linux / L4T (host) | R36.5.0 |
| Ubuntu (image) | 24.04 |
| ROS 2 | Jazzy |
| CUDA toolkit | 13.2 + `cuda-compat-orin-13-2` |
| PX4 messages | `px4_msgs` `release/1.17` (Pixhawks on PX4 1.17.x) |

The Jetson host must have the NVIDIA Container Toolkit configured. The container uses the host driver stack and includes CUDA development tooling for downstream packages. Ubuntu 24.04 has no CUDA 12.6 for this board, so the image ships the CUDA 13.2 toolkit plus NVIDIA's `cuda-compat-orin` user-space driver (first on `LD_LIBRARY_PATH`), which runs CUDA 13 on the JetPack 6 kernel driver without reflashing.

Images from `v0.5.1` are published here, all ROS 2 Jazzy. Earlier tags (`v0.1.0`–`v0.5.0`, Humble up to `v0.4.0`) were in the `mullet-ros2-base` package, which is deleted. Downstream images pin a tag, so they move when they choose.

This image provides a ready-to-use ROS 2 environment with the PX4 ROS message interfaces and Micro XRCE-DDS Agent already installed, reducing setup time and ensuring reproducible deployments across development machines and robots.

---

## ✨ Features

- 🤖 ROS 2 Jazzy for ARM64
- 🚁 Prebuilt PX4 ROS message interfaces (`px4_msgs`)
- 📡 Micro XRCE DDS Agent v2.4.3 installed system-wide
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

After the reboot, the UART interface will be ready on the host as
`/dev/ttyTHS1`. `docker-compose.yml` passes it through to the container, so
start Compose as usual:

```bash
MULLET_ROS_IMAGE_TAG=main docker compose run --rm ros2-base
```

The mapping is configured by `MULLET_UART_DEVICE` (default:
`/dev/ttyTHS1`) and needs no image rebuild after pulling a published image.
For a differently named host UART, set it before starting Compose; it still
appears in the container as `/dev/ttyTHS1`:

```bash
MULLET_UART_DEVICE=/dev/ttyUSB0 docker compose run --rm ros2-base
```

For a direct `docker run` invocation instead of Compose, pass the device
explicitly:

```bash
docker run --rm -it --runtime nvidia --network host \
  --device /dev/ttyTHS1:/dev/ttyTHS1 \
  ghcr.io/skymule-ai/mullet-base:main
```


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

For a released image, set `MULLET_ROS_IMAGE_TAG` to an immutable Git tag such as `v0.6.0` (for example, update `.env` or run `export MULLET_ROS_IMAGE_TAG=v0.6.0`).

## Test a CI image on the Orin

Every push to GitHub publishes an immutable image tag in the form `sha-<short-commit-sha>`.
After the workflow succeeds, use that tag on the Jetson without rebuilding locally:

```bash
git clone git@github.com:skymule-ai/mullet-base.git
cd mullet-base
cp .env.example .env
./scripts/test-on-orin.sh sha-<short-commit-sha>
```

The smoke test validates ROS/PX4 package availability, Micro XRCE-DDS Agent, CUDA compilation, and CUDA device visibility. The Jetson needs permission to pull the GHCR package: use `docker login ghcr.io` with a GitHub token that has `read:packages` if the package is private.

## Development and release workflow

1. Create a feature branch, for example `feat/r36.5-cuda-base`.
2. Push it to GitHub. CI builds and publishes a test image tagged `sha-<short-commit-sha>`.
3. Run `./scripts/test-on-orin.sh sha-<short-commit-sha>` on an Orin with the target JetPack version.
4. Open a pull request only after the Orin smoke test passes. Its check is the branch push build from step 2; the pull request does not build again.
5. Merge the pull request into `main`. CI publishes `:main` and a new immutable SHA image.
6. Create and push a Git tag such as `v0.6.0` only for an image that has passed hardware validation. CI publishes the matching `:v0.6.0` image and moves `:latest` to it.

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

* Version: `v2.4.3`, built from upstream unmodified
* Installed system-wide
* Builds Fast DDS 2.14 on fastcdr 2, the same pair ROS Jazzy ships. Keep them matched: v2.4.2
  (fastcdr 1) segfaults when it loads ROS's `libfastrtps.so.2.14`.

---

## 🧩 Extending the base image

It is recommended to keep this base image minimal and stable.

For project-specific dependencies, create a downstream image:

```Dockerfile
FROM ghcr.io/skymule-ai/mullet-base:v0.6.0

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
