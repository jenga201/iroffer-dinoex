# dinoex

Docker image for running Iroffer Dinoex (XDCC bot) in a container.

## What this image expects

Based on `Dockerfile`:
- Entrypoint: `entrypoint.sh`
- Home dir in container: `/home/iroffer`
- Host `${CONFIG_DIR}` is mounted to `/home/iroffer`
- Config dir in container: `/home/iroffer/config`
- Data dir in container: `/home/iroffer/data`
- Log dir in container: `/home/iroffer/logs`
- Exposed DCC port range: `30000-31000`

## Prerequisites

- Docker Engine
- Project contains `Dockerfile`
- Project contains `entrypoint.sh` (the Dockerfile copies it into the image)

## 1) Create local directories

```bash
mkdir -p ./config
```

On first start, the container creates `config`, `data`, and `logs` inside `${CONFIG_DIR}` as needed.

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
  --build-arg IROFFER_USER_ID="${IROFFER_USER_ID}" \
  --build-arg IROFFER_GROUP_ID="${IROFFER_GROUP_ID}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .
```

Run:

```bash
set -a
source ./.env
set +a
docker run -d \
  -t \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --env-file ./.env \
  -v "${CONFIG_DIR}:/home/iroffer" \
  -p "${PORT_RANGE}:${PORT_RANGE}" \
  "${IMAGE_NAME}:${IMAGE_TAG}"
```

Set `IROFFER_BOT_NAME` in `.env` to force `user_nick` in `iroffer.config` on every startup.
Set `PORT_RANGE` in `.env` (`START-END`) to force `tcprangestart` and `tcprangelimit` in `iroffer.config` on every startup.

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

- Container paths are fixed under `/home/iroffer` (`config`, `data`, `logs`), and the full tree is visible on the host through `${CONFIG_DIR}`.
- Iroffer runs in foreground mode; allocate a TTY (`tty: true` in compose or `docker run -t`).
- `PORT_RANGE` must be `START-END` (for example `30000-31000`). Startup applies `tcprangestart=START` and `tcprangelimit=END`.
- `EXPOSE` in `Dockerfile` is image metadata; effective published ports come from `-p`/compose `ports` using `PORT_RANGE`.
- Iroffer source URL and checksum are pinned in `Dockerfile` for reproducible builds.
- The image modifies a sample config under `/extras/sample.customized.config` during build.
- Place your bot config at `${CONFIG_DIR}/config/iroffer.config` on the host (mounted to `/home/iroffer/config/iroffer.config`).
- Shared files belong under `${CONFIG_DIR}/data`, and logs are written under `${CONFIG_DIR}/logs`.
- If `IROFFER_BOT_NAME` is set, `entrypoint.sh` rewrites `user_nick` in `/home/iroffer/config/iroffer.config` before startup.

