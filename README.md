# dinoex

Run Iroffer Dinoex (XDCC bot) with Docker.

## Quick start (copy/paste)

From the project root:

```bash
cp .env.example .env
mkdir -p ./config/data ./files
docker compose up -d --build
docker compose logs -f --tail=100
```

That is enough to stand up an instance.

## Where files end up on your host

- Bot config: `${CONFIG_DIR}/config/iroffer.config`
- Logs: `${CONFIG_DIR}/logs/`
- Pack list file: `${CONFIG_DIR}/data/packlist.txt`
- Shared XDCC files: `${DATA_DIR}/`

## First things to edit

1. Open `.env` and set `IROFFER_BOT_NAME` (optional, but recommended).
2. Open `${CONFIG_DIR}/config/iroffer.config` and set your IRC/network/channel values.
3. Put files you want to share into `${DATA_DIR}/`.

## Common commands

```bash
docker compose ps
docker compose logs -f
docker compose restart
docker compose down
```

## Environment variables

The main variables in `.env` are:

- `CONFIG_DIR` (default `./config`): mounted to `/home/iroffer`
- `DATA_DIR` (default `./files`): mounted to `/data`
- `PORT_RANGE` (default `30000-31000`): published by Docker and applied to `iroffer.config` on startup
- `HTTP_PORT` (optional): if set, startup sets/replaces `http_port` in `iroffer.config`

## Notes

- On first start, the container creates `${CONFIG_DIR}/config` and `${CONFIG_DIR}/logs` if missing.
- The default image config serves files from `/data`, which maps to `${DATA_DIR}`.
- If you change `PORT_RANGE`, keep it in `START-END` format (example: `30000-31000`).
- If you set `HTTP_PORT`, keep it in `1-65535`.

