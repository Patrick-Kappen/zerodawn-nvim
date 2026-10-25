# zerodawn-nvim

Addons for Neovim, in Lua, as one Nix flake. Each addon is a separate Neovim plugin. Your Neovim config chooses the addons and binds the keys; this repository has no config.

There are no addons yet. The planned ones are in [docs/todo.md](docs/todo.md).

## Install with Nix

This repository is a flake. It exports:

| Output | What |
|---|---|
| `packages.<system>.<addon>` | the addon as a Neovim plugin, without tests |
| `checks.<system>.*` | `pre-commit` and `tests-<addon>` |

Put the plugin in the packpath of your Neovim, then call `setup`:

```lua
require("zerodawn.<addon>").setup({})
```

## Develop

`direnv allow` (or `nix develop`), then `just check`. See [CONTRIBUTING.md](CONTRIBUTING.md).
