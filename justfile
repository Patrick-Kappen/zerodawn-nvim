# Run the tests of every addon, or of one: just test <addon>
test addon="":
    scripts/test.sh {{addon}}

# Lint and check the format
lint:
    stylua --check .
    luacheck .
    shellcheck scripts/*.sh
    shfmt -d -s -i 2 scripts

# Format the Nix, Lua and shell files with treefmt
fmt:
    nix fmt

# Run every check: lint, tests, nix flake check
check: lint test
    nix flake check

# Write the next version and its changelog section and commit both, on a branch: just release minor|patch|major
release level="minor":
    scripts/release.sh {{level}}
