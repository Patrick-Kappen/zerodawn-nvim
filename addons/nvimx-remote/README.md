# nvimx-remote

Opens Neovide on this machine against an nvimx server on another host, over SSH. Built for `x86_64-linux` and `aarch64-darwin`.

```
nix profile install github:Patrick-Kappen/zerodawn-nvim#nvimx-remote
nvimx-remote HOST NAME
```

- `HOST`: a host from your ssh config.
- `NAME`: the server name, letters, digits, `-` and `_`.

## What it does

1. `ssh HOST systemctl --user start nvimx@NAME`, and reads `XDG_RUNTIME_DIR` of HOST.
2. Forwards `$XDG_RUNTIME_DIR/nvimx/NAME.sock` of HOST to `$TMPDIR/nvimx-remote/HOST-NAME.sock`. No TCP port is opened.
3. Runs `neovide --server` on that socket. When Neovide stops, the tunnel stops.

## Needs on HOST

A systemd user unit `nvimx@.service` that runs `nvim --headless --listen %t/nvimx/%i.sock` and returns from `systemctl start` when the socket exists.

## Behaviour

- It uses the `ssh` of the system, so your ssh config, agent and macOS keychain apply.
- Neovide gives a remote server its own clipboard provider: copy and paste use the clipboard of this machine.
- Closing the window or Cmd-Q detaches. The server keeps running; more than one GUI can attach.

## Changes

<!-- changelog:start -->
## 0.1.0 — 2026-10-26

- First release.

[All changes](CHANGELOG.md)
<!-- changelog:end -->
