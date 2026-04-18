# dinoex

Docker image for running Iroffer Dinoex (XDCC bot) in a container.

## What this image expects

Based on `Dockerfile`:
- Entrypoint: `entrypoint.sh`
- Config dir in container: `/config`
- Data dir in container: `/files`
- Log dir in container: `/logs`
- Exposed DCC port range: `30000-31000`

## Prerequisites

- Docker Engine
- Project contains `Dockerfile`
- Project contains `entrypoint.sh` (the Dockerfile copies it into the image)

## 1) Create local directories

```bash
mkdir -p ./config ./files ./logs
```

## 2) Configure environment

Copy the tracked template and adjust values for your host:

```bash
cp ./.env.example ./.env
```

## 3) Build and run with Docker Compose (recommended)

```bash
docker compose up -d --build
```

Stop service:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f
```

## 4) Build and run with plain Docker (alternative)

Build:

```bash
set -a
source ./.env
set +a
docker build \
  --build-arg CONT_IMG_VER="${CONT_IMG_VER}" \
  --build-arg IROFFER_USER_ID="${IROFFER_USER_ID}" \
  --build-arg IROFFER_GROUP_ID="${IROFFER_GROUP_ID}" \
  --build-arg IROFFER_URL="${IROFFER_URL}" \
  --build-arg IROFFER_SHA256="${IROFFER_SHA256}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .
```

Run:

```bash
set -a
source ./.env
set +a
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --env-file ./.env \
  -v "${HOST_CONFIG_DIR}:${IROFFER_CONFIG_DIR}" \
  -v "${HOST_DATA_DIR}:${IROFFER_DATA_DIR}" \
  -v "${HOST_LOG_DIR}:${IROFFER_LOG_DIR}" \
  -p "${PORT_RANGE}:${PORT_RANGE}" \
  "${IMAGE_NAME}:${IMAGE_TAG}"
```

## Useful commands

```bash
docker logs -f "${CONTAINER_NAME}"
```

```bash
docker exec -it "${CONTAINER_NAME}" /bin/bash
```

```bash
docker stop "${CONTAINER_NAME}"
docker start "${CONTAINER_NAME}"
```

```bash
docker rm -f "${CONTAINER_NAME}"
```

## Notes

- The Dockerfile sets defaults for `IROFFER_CONFIG_DIR`, `IROFFER_DATA_DIR`, and `IROFFER_LOG_DIR`.
- The image modifies a sample config under `/extras/sample.customized.config` during build.
- If your `entrypoint.sh` expects `/config/mybot.config`, place your bot config at `./config/mybot.config` on the host.

