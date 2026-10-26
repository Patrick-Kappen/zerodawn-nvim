# zerodawn-nvim

Addons for Neovim, in Lua, as one Nix flake. Each addon is a separate Neovim plugin. Your Neovim config chooses the addons and binds the keys; this repository has no config.

The planned addons are in [docs/todo.md](docs/todo.md).

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
| [nvimx-remote](addons/nvimx-remote/README.md) | Neovide on this machine against an nvimx server on another host, over SSH |

## Develop

`direnv allow` (or `nix develop`), then `just check`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Changes

<!-- changelog:start -->
No release yet.

[All changes](CHANGELOG.md)
<!-- changelog:end -->
