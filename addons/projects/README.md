# projects

One picker for projects and worktrees, built on Snacks.picker. It has three scopes and always starts on the first:

1. `open`: the tmux worktree windows of the zerodawn-tmux addon `pair`.
2. `worktrees`: the git worktrees of the current repo, the open ones first.
3. `projects`: the recent folders of zoxide.

Choosing an entry changes the folder through the zerodawn-nvim addon `pair`, so tmux follows.

It fixes no key itself; the Neovim config binds `<A-p>` and `<leader>p` to `require("zerodawn.projects").pick`.

## Setup

```lua
require("zerodawn.projects").setup({
  command = "/path/to/zerodawn-tmux/pair/scripts/pair",
  tmux = "tmux",
  zoxide = "zoxide",
  worktree_root = "~/.worktrees",
})

vim.keymap.set("n", "<A-p>", require("zerodawn.projects").pick, { desc = "Project, worktree or folder" })
vim.keymap.set("n", "<leader>p", require("zerodawn.projects").pick, { desc = "Project, worktree or folder" })
```

`zerodawn.pair` must be set up before the first switch; the default switch calls its `follow(dir)`.

| Option | Use |
|---|---|
| `command` | Path of the pair script of the zerodawn-tmux addon. Must be executable. |
| `tmux` | The tmux command that loads your config; the pair script gets it as `--tmux`. |
| `zoxide` | The zoxide command; its recent folders are the projects. Default `zoxide`. |
| `worktree_root` | Where Ctrl-n creates a worktree. Default `~/.worktrees`. |
| `switch` | `function(dir)` that changes the folder. Default: `require("zerodawn.pair").follow(dir)`. |
| `confirm` | `function(question)` that returns true to delete. Default: `vim.fn.confirm` with Delete and Cancel. |
| `snacks` | The module that has `picker`; default `require("snacks")`. For tests. |

## Keys in the picker

| Key | Use |
|---|---|
| `Enter` | Switch to the entry, or to the typed folder (a typed path starts with `/`, `~` or `.`). |
| `Tab` | Go to the next scope: open, worktrees, projects, then open again. Typing searches the current scope. |
| `Ctrl-n` | New worktree: type the branch name, Enter creates it under `worktree_root`. |
| `Ctrl-d` | Delete a worktree; it asks first when pi runs there. |

The current folder of this nvim has `▶`. An open entry has `●`; an entry where the agent (pi) runs has `π`.

## Functions

| Function | Use |
|---|---|
| `setup(opts)` | Checks the options and stores them. Binds no key. |
| `pick()` | Opens the picker. Returns the Snacks picker. |

## Changes

<!-- changelog:start -->
<!-- changelog:end -->
