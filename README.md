# zerodawn-nvim

Addons for Neovim, in Lua, as one Nix flake. Each addon is a separate Neovim plugin. Your Neovim config chooses the addons and binds the keys; this repository has no config.

The open work is in [docs/todo/TODO.md](docs/todo/TODO.md).

## Install with Nix

This repository is a flake. It exports:

| Output | What |
|---|---|
| `packages.<system>.<addon>` | the addon: a Neovim plugin, or the program from its `package.nix`; without tests |
| `checks.<system>.*` | `pre-commit` and `tests-<addon>` |

Put the plugin in the packpath of your Neovim, then call `setup`:

```lua
require("zerodawn.<addon>").setup({})
```

## Addons

| Addon | What |
|---|---|
| [pair](addons/pair/README.md) | Keeps this nvim server and a tmux client on the same repo and worktree; needs the zerodawn-tmux addon pair |
| [projects](addons/projects/README.md) | One picker for projects and worktrees, built on Snacks.picker; needs the zerodawn-tmux addon pair and zoxide |
| [nvimx-remote](addons/nvimx-remote/README.md) | Neovide on this machine against an nvim server on another host, over SSH |

## Develop

`direnv allow` (or `nix develop`), then `just check`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Changes

<!-- changelog:start -->
## 0.1.2 — 2026-10-27

### pair 0.1.2

- block a tmux switch once, not once for each hook

## 0.1.1 — 2026-10-27

### pair 0.1.1

- start opens no second terminal when a client is paired

## 0.1.0 — 2026-10-26

### nvimx-remote 0.1.0

- First release.

### pair 0.1.0

- First release.

[All changes](CHANGELOG.md)
<!-- changelog:end -->
