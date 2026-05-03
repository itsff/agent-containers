#!/usr/bin/env bash
set -euo pipefail

PROJ="$(basename "$(pwd)")"
DEFAULT_NAME="pi-${PROJ}-${USER:-user}-$(date +%s)-$$"
NAME="${PI_NAME:-$DEFAULT_NAME}"
CONTAINER_HOME="${CONTAINER_HOME:-/home/ubuntu}"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
MOUNT_HOME_RO=1
PI_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-home-ro)
      MOUNT_HOME_RO=0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        PI_ARGS+=("$1")
        shift
      done
      break
      ;;
    *)
      PI_ARGS+=("$1")
      ;;
  esac
  shift
done

mkdir -p "$HOME/.pi"

if command -v podman >/dev/null 2>&1; then
  RUNTIME=(podman run --rm --tty --interactive --userns=keep-id --user "${HOST_UID}:${HOST_GID}")
else
  RUNTIME=(docker run --rm --tty --interactive --user "${HOST_UID}:${HOST_GID}")
fi

MOUNTS=(
  -v "$HOME/.pi:${CONTAINER_HOME}/.pi:rw"
  -v "$(pwd):/app:rw"
)

if [ "$MOUNT_HOME_RO" -eq 1 ]; then
  MOUNTS+=( -v "$HOME:/host-home:ro" )
fi

exec "${RUNTIME[@]}" \
  --name "$NAME" \
  -e HOME="${CONTAINER_HOME}" \
  -e PI_CODING_AGENT_DIR="${CONTAINER_HOME}/.pi/agent" \
  --add-host=host.docker.internal:host-gateway \
  "${MOUNTS[@]}" \
  pi "${PI_ARGS[@]}"
