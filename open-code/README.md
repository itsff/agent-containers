# Open Code

## Build Instructions

Use the top level `Makefile` to build this. It injects things in to the build
so the container works correctly for your user under `podman`.

```bash
make open-code
```

You can add more local tools to the container to be installed via `apt-get` by
extending the `LOCAL_TOOLS` list in the top-level `Makefile`.

## Run Instructions
- Use the included launcher script: `open-code/run-opencode.sh`
- Symlink it into `~/.local/bin` as `opencode` (or copy it there)
- Startup is a bit slow due to container startup time, but taking ~5s startup penalty for safety measures is not so bad.
- I also add the host mapping to host.docker.internal so the container can access your localhost (useful for the agent-browser or similar MCPs to access your apps running on localhost)
- By default the script publishes no ports (safe for multiple concurrent runs)
- Publish ports only when needed with `--ports 3000-3010` (or `-p 3000-3010`)
- Each launch gets a unique container name by default, so you can run multiple `open-code` containers from the same directory
- If you run a web app in the container, bind it to `0.0.0.0` so it is reachable from your host browser
- Mount targets default to `/home/ubuntu`; override with `CONTAINER_HOME=/some/home` if your image uses a different home path
- The container process runs as your host UID/GID on both podman and docker to avoid bind-mount permission issues
- The script always mounts:
  1. opencode global state - UI state, command history, model preferences, recently opened files
  2. opencode global share - Auth tokens, session data, LSP servers, git snapshots for undo, logs
  3. opencode global config - User configuration: themes, keybindings, custom commands, plugins
  4. the repo you work - mounted as current PWD when executing `opencode` in your terminal
- It also mounts these if they exist:
  1. `~/.vim` and `~/.vimrc`
  2. `~/.config/nvim`, `~/.local/share/nvim`, and `~/.local/state/nvim`
  3. `~/.gitconfig` (read-only)

```bash
chmod +x ./open-code/run-opencode.sh
ln -sf "$(pwd)/open-code/run-opencode.sh" "$HOME/.local/bin/opencode"

# optional override for published port range
opencode --ports 3000-3010

# same via env var
OPENCODE_PORT_RANGE=3000-3010 opencode

# optional fixed name for a specific run
OPENCODE_NAME=open-code-test opencode

# optional override if container home is not /home/ubuntu
CONTAINER_HOME=/home/node opencode
```

If you previously ran with a different UID/GID and got sqlite read-only errors,
fix ownership once on your host:

```bash
chown -R "$(id -u):$(id -g)" "$HOME/.local/share/opencode" "$HOME/.local/state/opencode" "$HOME/.config/opencode"
```

## References

* [Documentation](https://opencode.ai/docs)
* [Github Repo](https://github.com/sst/opencode)
