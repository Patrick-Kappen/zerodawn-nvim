# AGENTS.md

- The zerodawn-tmux addon `pair` calls `require("zerodawn.pair").follow(dir)` over RPC. Keep that name and signature.
- This addon calls `<command> --tmux <tmux> attach|open SERVER DIR`. Exit 3 from open means no paired client: stop the pair.
- Do nothing when the target is the current folder; that stops loops between DirChanged and the tmux hooks.
- `tests/pair_test.lua` uses a fake pair script that logs its arguments.
