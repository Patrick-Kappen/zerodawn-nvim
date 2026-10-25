# Open points

- Addon `pair`: nvimx-gui and a wezterm/tmux window stay on the same repo and worktree. It works only after the pair key; a plain nvimx does nothing.
  - The config binds the pair key (`<leader>i` for now).
  - `DirChanged` (global) calls the pair command of zerodawn-tmux. The command opens or makes the tmux session of the repo and the window of the worktree.
  - zerodawn-tmux calls back through `nvim --server` when you change the session or window in tmux.
  - Save the auto-session on `FocusLost`, so a crash does not lose the layout.
  - Ctrl-d on a worktree where pi runs: show a notification and ask yes/no.
  - A folder that is not in git gets a plain tmux session without pi.
- Project picker (`<leader>p`, `plugins/projects.lua` in nixos-config): it sorts worktrees first but does not show which entries are open. Mark the current entry and the entries that have a tmux window, and sort the open entries first.
