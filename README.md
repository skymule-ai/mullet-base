# mullet_ros_base

Base ROS 2 Humble layer for ARM64 with PX4 ROS 2 packages prebuilt.

## Build

```bash
docker compose build
```

## Run

```bash
docker compose run --rm ros2-base
```

## Update package sources

Edit `repos/ros2.repos`, then rebuild:

```bash
docker compose build
```

## Add extra apt packages

Prefer adding packages in a downstream Dockerfile so this base stays stable:

```Dockerfile
FROM mullet-ros2-base:latest
RUN apt-get update \
  && apt-get install -y --no-install-recommends <your-packages> \
  && rm -rf /var/lib/apt/lists/*
```

If you want them in the base, add them to the `Dockerfile` apt list and rebuild.
