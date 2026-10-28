# Save the auto-session on FocusLost

A crash of nvimx loses the layout since the last session save. Save the auto-session on `FocusLost`. The change is in the nvimx config in nixos-config, not in an addon.

## Source

- `docs/todo.md`, owner's notes, before 2026-10-28, under the addon `pair`.

## Original text

- Save the auto-session on `FocusLost`, so a crash does not lose the layout.

## Parts that exist

- `FocusLost` saves the buffers only: `packages/nvim/nvimx/config/lua/core/autocmds.lua` in nixos-config.
- The auto-session setup: `packages/nvim/nvimx/config/lua/plugins/session.lua` in nixos-config.
