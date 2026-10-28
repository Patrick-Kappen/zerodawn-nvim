# Run the tests of every addon, or of one: just test <addon>
test addon="":
    scripts/test.sh {{addon}}

# Run the tests for the changed paths: an addon path runs its tests, any other path runs every test
test-changed *files:
    scripts/test-changed.sh {{files}}

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

# Bump every addon that changed since its last tag, and the repository; the level comes from the "Change:" trailers
bump-changed:
    scripts/bump-changed.sh

# Fail when an addon changed since its last tag without a higher version; CI runs this on a release PR
release-check:
    scripts/release-check.sh

# Write the changelog blocks into the README of each addon and the root README
notes:
    scripts/notes.sh
