#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Build a fresh image and publish it to Docker Hub.

Environment variables:
  DOCKERHUB_NAMESPACE   Required unless DOCKERHUB_REPO is set.
  DOCKERHUB_REPO        Optional full repo name (e.g. user/iroffer-dinoex).
  IMAGE_NAME            Local image name (default: iroffer-dinoex).
  IMAGE_TAG             Image tag (default: local).
  PUSH_LATEST           Push :latest too (default: 1).
  IROFFER_USER_ID       Build arg (default: 1000).
  IROFFER_GROUP_ID      Build arg (default: 1000).
  DOCKERHUB_USERNAME    Optional; used with DOCKERHUB_TOKEN for non-interactive login.
  DOCKERHUB_TOKEN       Optional Docker Hub access token.

Examples:
  DOCKERHUB_NAMESPACE=myuser ./publish-dockerhub.sh
  DOCKERHUB_REPO=myorg/iroffer-dinoex IMAGE_TAG=v1.2.3 ./publish-dockerhub.sh
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

load_env_file() {
  if [ -f ".env" ]; then
    # shellcheck disable=SC1091
    set -a
    . ./.env
    set +a
  fi
}

docker_login_if_requested() {
  if [ -n "${DOCKERHUB_TOKEN:-}" ] || [ -n "${DOCKERHUB_USERNAME:-}" ]; then
    if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ -z "${DOCKERHUB_TOKEN:-}" ]; then
      echo "Both DOCKERHUB_USERNAME and DOCKERHUB_TOKEN are required for scripted login." >&2
      exit 1
    fi

    echo "Logging in to Docker Hub as ${DOCKERHUB_USERNAME}..."
    printf '%s' "${DOCKERHUB_TOKEN}" | docker login --username "${DOCKERHUB_USERNAME}" --password-stdin
  fi
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  require_cmd docker
  load_env_file

  IMAGE_NAME="${IMAGE_NAME:-iroffer-dinoex}"
  IMAGE_TAG="${IMAGE_TAG:-local}"
  PUSH_LATEST="${PUSH_LATEST:-1}"
  IROFFER_USER_ID="${IROFFER_USER_ID:-1000}"
  IROFFER_GROUP_ID="${IROFFER_GROUP_ID:-1000}"

  if [ -n "${DOCKERHUB_REPO:-}" ]; then
    repo="${DOCKERHUB_REPO}"
  else
    if [ -z "${DOCKERHUB_NAMESPACE:-}" ]; then
      echo "Set DOCKERHUB_NAMESPACE or DOCKERHUB_REPO before running." >&2
      exit 1
    fi
    repo="${DOCKERHUB_NAMESPACE}/${IMAGE_NAME}"
  fi

  image_ref="${repo}:${IMAGE_TAG}"

  docker_login_if_requested

  echo "Building fresh image: ${image_ref}"
  docker build \
    --pull \
    --no-cache \
    --build-arg IROFFER_USER_ID="${IROFFER_USER_ID}" \
    --build-arg IROFFER_GROUP_ID="${IROFFER_GROUP_ID}" \
    -t "${image_ref}" \
    .

  echo "Pushing ${image_ref}"
  docker push "${image_ref}"

  if [ "${PUSH_LATEST}" = "1" ] && [ "${IMAGE_TAG}" != "latest" ]; then
    latest_ref="${repo}:latest"
    echo "Tagging and pushing ${latest_ref}"
    docker tag "${image_ref}" "${latest_ref}"
    docker push "${latest_ref}"
  fi

  echo "Done: ${image_ref}"
}

main "$@"

