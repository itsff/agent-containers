#!/usr/bin/env bash
set -euo pipefail

PROJ="$(basename "$(pwd)")"
DEFAULT_NAME="open-code-${PROJ}-${USER:-user}-$(date +%s)-$$"
NAME="${OPENCODE_NAME:-$DEFAULT_NAME}"
PORT_RANGE="${OPENCODE_PORT_RANGE:-}"
CONTAINER_HOME="${CONTAINER_HOME:-/home/ubuntu}"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
OPENCODE_ARGS=()
GUI_ENV=()
GUI_MOUNTS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ports|-p)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Missing value for --ports/-p (example: 3000-3010)" >&2
        exit 1
      fi
      PORT_RANGE="$1"
      ;;
    --ports=*)
      PORT_RANGE="${1#*=}"
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        OPENCODE_ARGS+=("$1")
        shift
      done
      break
      ;;
    *)
      OPENCODE_ARGS+=("$1")
      ;;
  esac
  shift
done

mkdir -p "$HOME/.local/state/opencode" "$HOME/.local/share/opencode" "$HOME/.config/opencode"

if command -v podman >/dev/null 2>&1; then
  RUNTIME=(podman run --rm --tty --interactive --userns=keep-id --user "${HOST_UID}:${HOST_GID}")
else
  RUNTIME=(docker run --rm --tty --interactive --user "${HOST_UID}:${HOST_GID}")
fi

MOUNTS=(
  -v "$HOME/.local/state/opencode:${CONTAINER_HOME}/.local/state/opencode"
  -v "$HOME/.local/share/opencode:${CONTAINER_HOME}/.local/share/opencode"
  -v "$HOME/.config/opencode:${CONTAINER_HOME}/.config/opencode"
  -v "$(pwd):/app:rw"
)

if [ -d "$HOME/.vim" ]; then
  MOUNTS+=( -v "$HOME/.vim:${CONTAINER_HOME}/.vim" )
fi
if [ -f "$HOME/.vimrc" ]; then
  MOUNTS+=( -v "$HOME/.vimrc:${CONTAINER_HOME}/.vimrc" )
fi
if [ -d "$HOME/.config/nvim" ]; then
  MOUNTS+=( -v "$HOME/.config/nvim:${CONTAINER_HOME}/.config/nvim" )
fi
if [ -d "$HOME/.local/share/nvim" ]; then
  MOUNTS+=( -v "$HOME/.local/share/nvim:${CONTAINER_HOME}/.local/share/nvim" )
fi
if [ -d "$HOME/.local/state/nvim" ]; then
  MOUNTS+=( -v "$HOME/.local/state/nvim:${CONTAINER_HOME}/.local/state/nvim" )
fi
if [ -f "$HOME/.gitconfig" ]; then
  MOUNTS+=( -v "$HOME/.gitconfig:${CONTAINER_HOME}/.gitconfig:ro" )
fi

# Pass through Wayland/X11 so clipboard tools inside the container can talk to
# the host display server.
HOST_XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${HOST_UID}}"

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  if [[ "${WAYLAND_DISPLAY}" = /* ]]; then
    WAYLAND_SOCKET="${WAYLAND_DISPLAY}"
    WAYLAND_DIR="$(dirname "${WAYLAND_SOCKET}")"
    WAYLAND_NAME="$(basename "${WAYLAND_SOCKET}")"
    CONTAINER_XDG_RUNTIME_DIR="${WAYLAND_DIR}"
  else
    WAYLAND_SOCKET="${HOST_XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}"
    WAYLAND_DIR="${HOST_XDG_RUNTIME_DIR}"
    WAYLAND_NAME="${WAYLAND_DISPLAY}"
    CONTAINER_XDG_RUNTIME_DIR="${HOST_XDG_RUNTIME_DIR}"
  fi

  if [ -S "${WAYLAND_SOCKET}" ]; then
    GUI_MOUNTS+=( -v "${WAYLAND_DIR}:${WAYLAND_DIR}" )
    GUI_ENV+=( -e "XDG_RUNTIME_DIR=${CONTAINER_XDG_RUNTIME_DIR}" )
    GUI_ENV+=( -e "WAYLAND_DISPLAY=${WAYLAND_NAME}" )
  fi
fi

if [ -n "${DISPLAY:-}" ] && [ -d "/tmp/.X11-unix" ]; then
  GUI_ENV+=( -e "DISPLAY=${DISPLAY}" )
  GUI_MOUNTS+=( -v "/tmp/.X11-unix:/tmp/.X11-unix:ro" )

  if [ -n "${XAUTHORITY:-}" ] && [ -f "${XAUTHORITY}" ]; then
    GUI_MOUNTS+=( -v "${XAUTHORITY}:${CONTAINER_HOME}/.Xauthority:ro" )
    GUI_ENV+=( -e "XAUTHORITY=${CONTAINER_HOME}/.Xauthority" )
  elif [ -f "${HOME}/.Xauthority" ]; then
    GUI_MOUNTS+=( -v "${HOME}/.Xauthority:${CONTAINER_HOME}/.Xauthority:ro" )
    GUI_ENV+=( -e "XAUTHORITY=${CONTAINER_HOME}/.Xauthority" )
  fi
fi

PORT_FLAGS=()
if [ -n "$PORT_RANGE" ]; then
  PORT_FLAGS=( -p "${PORT_RANGE}:${PORT_RANGE}" )
fi

exec "${RUNTIME[@]}" \
  --name "$NAME" \
  -e HOME="${CONTAINER_HOME}" \
  "${GUI_ENV[@]}" \
  "${PORT_FLAGS[@]}" \
  --add-host=host.docker.internal:host-gateway \
  "${MOUNTS[@]}" \
  "${GUI_MOUNTS[@]}" \
  open-code "${OPENCODE_ARGS[@]}"
