# AGENTS.md

nvimx-remote is a program, not a Neovim plugin: `package.nix` builds `nvimx-remote.sh` with writeShellApplication.

- Keep `ssh` out of `runtimeInputs`. The macOS ssh reads `UseKeychain`; the nixpkgs ssh fails on it.
- `NAME` expands on the client side in the ssh command. Keep the check that allows only letters, digits, `-` and `_`.
- The server contract (`nvim@NAME`, socket at `$XDG_RUNTIME_DIR/nvim/NAME.sock`) is in README.md. Change it only together with the unit in nixos-config.
- `tests/args_test.lua` needs no network: it checks the argument errors and the missing ssh.
