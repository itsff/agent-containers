# Pi

## Build Instructions

Use the top level `Makefile` to build this. It injects things in to the build
so the container works correctly for your user under `podman`.

```bash
make pi
```

You can add more local tools to the container to be installed via `apt-get` by
extending the `LOCAL_TOOLS` list in the top-level `Makefile`.

## First time setup

Pi stores auth, settings, sessions, prompts, skills, themes, and extension data
under `~/.pi`, so this launcher mounts `~/.pi` read/write for persistence.

```bash
mkdir -p ~/.pi
```

## Run Instructions

Use the included launcher script:

```bash
chmod +x ./pi/run-pi.sh
ln -sf "$(pwd)/pi/run-pi.sh" "$HOME/.local/bin/pi"
```

Default run (mounts current repo rw, mounts `~/.pi` rw, mounts host home ro at
`/host-home`):

```bash
pi
```

Disable read-only host home mount:

```bash
pi --no-home-ro
```

Pass Pi CLI args through to the container command:

```bash
pi -- --model sonnet:high
```

Note: If you're running rootless `podman` you'll need `--userns=keep-id`; the
launcher script adds that automatically when `podman` is detected.

## References

* [Documentation](https://pi.dev/docs/latest)
* [Github Repo](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent)
