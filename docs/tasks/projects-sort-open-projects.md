# Sort the open entries first in the projects scope of the picker

The scope `worktrees` sorts the open entries first. The scope `projects` keeps the order of `zoxide query -l`, so an open project can be at the bottom. Sort the open entries first in that scope too.

## Source

- `docs/todo.md`, owner's notes, before 2026-10-28.

## Original text

- Project picker (`<leader>p`, `plugins/projects.lua` in nixos-config): it sorts worktrees first but does not show which entries are open. Mark the current entry and the entries that have a tmux window, and sort the open entries first.

## Parts that exist

- `worktree_items` sorts open entries first; `project_items` does not sort. Both are in `addons/projects/lua/zerodawn/projects/init.lua`.

## Related

- [projects-mark-current](projects-mark-current.md)
