# mullet_ros_base

Base ROS 2 Humble layer for ARM64 with PX4 ROS 2 packages prebuilt and Micro XRCE DDS Agent installed.

## Build locally

```bash
docker compose build
```

## Run locally

```bash
docker compose run --rm ros2-base
```

## Pull on Jetson

```bash
docker pull ghcr.io/skymule-ai/mullet-ros2-base:latest
docker compose up -d
```

## Update package sources

Edit `repos/ros2.repos`, then rebuild:

```bash
docker compose build
```

## Included software

- PX4 ROS 2 packages from `repos/ros2.repos`
- Micro XRCE DDS Agent v2.4.2 (system-wide)
- Micro XRCE DDS Agent uses patched `CMakeLists.txt` from `patches/CMakeLists.txt`

## Add extra apt packages

Prefer adding packages in a downstream Dockerfile so this base stays stable:

```Dockerfile
FROM ghcr.io/skymule-ai/mullet-ros2-base:latest
RUN apt-get update \
  && apt-get install -y --no-install-recommends <your-packages> \
  && rm -rf /var/lib/apt/lists/*
```

If you want them in the base, add them to the `Dockerfile` apt list and rebuild.
