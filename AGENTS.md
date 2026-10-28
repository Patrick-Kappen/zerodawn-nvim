# AGENTS.md

Neovim addons in Lua. Nix flake with one Neovim plugin package for each addon.

## Layout

- `addons/<name>/`: one addon, a Neovim plugin. Code in `lua/zerodawn/<name>/`, entry `require("zerodawn.<name>").setup(opts)`. Tests in `tests/*_test.lua`; each runs with `nvim -l` in its own headless nvim. Every addon has `VERSION`, `CHANGELOG.md`, `README.md`, `AGENTS.md` and at least one test; the flake fails without them.
- `docs/decisions.md`: why things are the way they are. Read it before a structural change; add a numbered entry when you make one.
- `docs/todo/TODO.md` is the open work, `docs/todo/BACKLOG.md` the work for later. Each item has one file in `docs/tasks/`. Remove an item and its file when it is done. Do not act on an item unless asked.

## Rules

- This repository holds addons, not a config. The Neovim (nvimx) config that loads them is in the owner's nixos-config. An addon binds no keys; the config binds them.
- An addon that talks to tmux uses only the command line of zerodawn-tmux. It shows an error that names the missing command when it is not installed.
- Commit subject: `<scope>: what changed`, scope is an addon name, `release`, `ci`, `docs`, `flake`, `repo` or `deps`. Max 72 characters. Add one trailer `Change: fix|feature|breaking`; it sets the version level. The subjects become the changelog.
- Work on a branch and worktree add ~/.worktrees and open a PR; `main` is protected by a hook.
- Do not edit a `VERSION` or `CHANGELOG.md` by hand. A release is `just bump-changed` on a branch, as its own PR with a `release:` title.
- Do not add a dependency without an entry in `docs/decisions.md`.
- Fail loud: no fallback that hides a missing input. Errors name the file or the id and the next step.
- No comments except for a reason the code cannot show. English everywhere.

## Checks

- `just check`: stylua, luacheck, shellcheck, shfmt, the tests, `nix flake check`.
- `just test [addon]` and `just lint` for one part.
