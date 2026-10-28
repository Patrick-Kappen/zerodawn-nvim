# Decisions

Short records of choices that shape the repository. Newest at the top.

## 5. projects uses Snacks.picker (2026-10-27)

The addon `projects` opens its picker with Snacks.picker and it is the only dependency of this repository outside Neovim itself. `opts.snacks` takes a fake in the tests. Reason: the nvimx config already runs snacks.nvim and its picker gives the search, the actions and the layout; a second picker would duplicate that. `setup` fails loud when snacks.nvim is not on the runtimepath.

## 4. An addon can be a program (2026-10-26)

An addon with a `package.nix` builds from that file; the others build as Neovim plugins. The first one is `nvimx-remote`, a shell program that runs on the Mac. Reason: a program that belongs to Neovim gets the same rules as a plugin: README, AGENTS.md, tests, commit scope, version and changelog. Its tests also run with `nvim -l`, and call the program with `vim.system`.

## 3. A version for each addon (2026-10-26)

Each addon has `VERSION` and `CHANGELOG.md` and the tag `<addon>-v<version>`; the repository has `VERSION`, `CHANGELOG.md` and the tag `v<version>`. The version level comes from a `Change:` trailer on each commit. Reason: the same release model as zerodawn-pi, and an addon gets a new version only when it changed.

## 2. An addon binds no keys (2026-10-25)

An addon exports `setup(opts)` and functions. The Neovim config binds the keys to these functions. Reason: keys are personal and change often, and the addon stays usable in another config.

## 1. Addons here, the config in nixos-config (2026-10-25)

This repository holds addons only: code that does one task and has tests. The nvimx config (options, plugin choice, keys) stays in nixos-config. Reason: the same split as zerodawn-pi and pi. Addons get versions, tests and CI, and the config stays quick to change.
