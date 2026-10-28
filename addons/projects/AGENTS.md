# AGENTS.md

- The addon binds no keys; the Neovim config binds `<A-p>` and `<leader>p` to `pick()`. Keep it that way (docs/decisions.md 2).
- The picker is Snacks.picker; `opts.snacks` injects a fake in the tests. The addon has no other dependency, and `setup` fails loud when `snacks` or `zoxide` is missing.
- `pair list` is the contract of the zerodawn-tmux addon `pair`: `REPO<TAB>WORKTREE<TAB>WINDOW<TAB>AGENT`; `AGENT=1` means the agent (pi) runs there. A line that does not match is an error.
- A switch calls `require("zerodawn.pair").follow(dir)` by default, never a plain `cd`, so tmux follows. `opts.switch` can replace it.
- `tests/projects_test.lua` uses a fake pair script, a fake zoxide, a fake `zerodawn.pair` module and a fake Snacks picker, so it needs no tmux and no git remote.
