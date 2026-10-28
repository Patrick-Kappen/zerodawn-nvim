# Mark the current entry in the projects picker

The picker of the addon `projects` marks open entries with `●` and entries that run pi with `π`. It does not show which entry is the current folder of this nvim. Give the entry of `vim.fn.getcwd()` its own mark in each scope.

## Source

- `docs/todo.md`, owner's notes, before 2026-10-28.

## Original text

- Project picker (`<leader>p`, `plugins/projects.lua` in nixos-config): it sorts worktrees first but does not show which entries are open. Mark the current entry and the entries that have a tmux window, and sort the open entries first.

## Parts that exist

- The mark for open entries and for pi: `format` in `addons/projects/lua/zerodawn/projects/init.lua`.

## Related

- [projects-sort-open-projects](projects-sort-open-projects.md)
