# pair

Keeps this nvim server and a tmux client on the same repo and worktree. tmux holds one session for each repo and one window for each worktree. Needs the zerodawn-tmux addon `pair`.

It works only after `start()`. A plain nvim does nothing.

## Setup

```lua
require("zerodawn.pair").setup({
  command = "/path/to/zerodawn-tmux/pair/scripts/pair",
  tmux = "tmuxw",
  terminal = { "wezterm", "start", "--class", "nvimx-ide", "--" },
  switch = function(dir) vim.cmd.cd(dir) end,
})
vim.keymap.set("n", "<leader>i", require("zerodawn.pair").start)
```

| Option | Use |
|---|---|
| `command` | Path of the pair script of the zerodawn-tmux addon. Must be executable. |
| `tmux` | The tmux command that loads your config. |
| `terminal` | Opens a terminal; the attach command is added at the end. |
| `switch` | `function(dir)` that changes the folder, for example with your session restore. Default: `vim.cmd.cd`. |

## Functions

| Function | Use |
|---|---|
| `start()` | Opens a terminal on the tmux window of the current folder, paired with this server. Needs a server address (`--listen`). |
| `stop()` | Stops the sync from this side. |
| `active()` | True while the pair is on. |
| `follow(dir)` | Called by tmux over RPC. Changes to `dir`; with modified buffers it refuses and sends tmux back. |

After `start()`, every global folder change moves tmux. When no tmux client is paired any more, the pair stops with a message.

## Changes

<!-- changelog:start -->
No release yet.

[All changes](CHANGELOG.md)
<!-- changelog:end -->
