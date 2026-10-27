{
  description = "zerodawn-nvim: Neovim addons (Lua)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      forAll =
        f:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            f {
              inherit system;
              pkgs = nixpkgs.legacyPackages.${system};
            }
          );
      inherit (nixpkgs) lib;
      # Every addon has a VERSION, a CHANGELOG.md, a README.md, an AGENTS.md and at least one test; a missing one fails the evaluation.
      checkAddon =
        name:
        let
          dir = ./addons + "/${name}";
          tests = lib.optionals (builtins.pathExists (dir + "/tests")) (
            lib.fileset.toList (
              lib.fileset.fileFilter (file: lib.hasSuffix "_test.lua" file.name) (dir + "/tests")
            )
          );
        in
        if !builtins.pathExists (dir + "/VERSION") then
          throw "addons/${name}/VERSION is missing; write the first version, for example 0.1.0"
        else if !builtins.pathExists (dir + "/CHANGELOG.md") then
          throw "addons/${name}/CHANGELOG.md is missing; write a file with the line # Changelog"
        else if !builtins.pathExists (dir + "/README.md") then
          throw "addons/${name}/README.md is missing; describe the addon, its setup() options and its functions"
        else if !builtins.pathExists (dir + "/AGENTS.md") then
          throw "addons/${name}/AGENTS.md is missing; write what the addon does, what it needs and what to check"
        else if tests == [ ] then
          throw "addons/${name}/tests has no *_test.lua; add a test"
        else
          name;
      # A repository without an addons/ directory has no addons yet; that is not an error.
      addons = map checkAddon (
        lib.optionals (builtins.pathExists ./addons) (
          builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./addons))
        )
      );
      # An addon with a package.nix is a program, for example a client that runs on another machine; the rest are Neovim plugins.
      plugin =
        pkgs: name:
        let
          version = lib.trim (builtins.readFile (./addons + "/${name}/VERSION"));
        in
        if builtins.pathExists (./addons + "/${name}/package.nix") then
          pkgs.callPackage (./addons + "/${name}/package.nix") { inherit version; }
        else
          pkgs.vimUtils.buildVimPlugin {
            pname = "zerodawn-${name}";
            inherit version;
            src = lib.fileset.toSource {
              root = ./addons + "/${name}";
              fileset = lib.fileset.difference (./addons + "/${name}") (./addons + "/${name}/tests");
            };
          };
      runTests =
        pkgs: name:
        pkgs.runCommand "tests-${name}"
          {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./scripts/test.sh
                (./addons + "/${name}")
              ];
            };
            nativeBuildInputs = [
              pkgs.neovim-unwrapped
              pkgs.bash
              pkgs.git
            ];
          }
          ''
            cp -r "$src" src
            chmod -R u+w src
            cd src
            HOME="$TMPDIR" bash scripts/test.sh ${name}
            touch "$out"
          '';
    in
    {
      # treefmt, because the central git pre-commit hook runs nix fmt -- --fail-on-change <staged files>.
      formatter = forAll (
        { pkgs, ... }:
        pkgs.treefmt.withConfig {
          runtimeInputs = [
            pkgs.nixfmt
            pkgs.stylua
            pkgs.shfmt
          ];
          settings = {
            on-unmatched = "info";
            formatter = {
              nixfmt = {
                command = "nixfmt";
                includes = [ "*.nix" ];
              };
              stylua = {
                command = "stylua";
                includes = [ "*.lua" ];
              };
              shfmt = {
                command = "shfmt";
                options = [
                  "-w"
                  "-s"
                  "-i"
                  "2"
                ];
                includes = [
                  "*.sh"
                ];
              };
            };
          };
        }
      );
      packages = forAll (
        { pkgs, ... }:
        lib.genAttrs addons (plugin pkgs)
      );

      checks = forAll (
        { system, pkgs }:
        {
          pre-commit = git-hooks.lib.${system}.run {
            src = self;
            hooks = {
              detect-private-keys.enable = true;
              check-added-large-files.enable = true;
              check-merge-conflicts.enable = true;
              end-of-file-fixer.enable = true;
              trim-trailing-whitespace.enable = true;
              no-commit-to-branch.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
              stylua.enable = true;
              luacheck.enable = true;
              shellcheck = {
                enable = true;
                excludes = [ "^\\.envrc$" ];
              };
              shfmt = {
                enable = true;
                settings.indent = 2;
              };
              commit-msg = {
                enable = true;
                name = "commit message: <addon|area>: subject";
                entry = "${pkgs.bash}/bin/bash scripts/check-commit-msg.sh";
                stages = [ "commit-msg" ];
                pass_filenames = true;
              };
              branch-msgs = {
                enable = true;
                name = "every commit on the branch has <scope>: subject";
                entry = "${pkgs.bash}/bin/bash scripts/check-branch-msgs.sh";
                stages = [ "pre-push" ];
                pass_filenames = false;
                always_run = true;
              };
              gitleaks = {
                enable = true;
                name = "gitleaks";
                entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --staged --redact --no-banner";
                pass_filenames = false;
              };
            };
          };
        }
        // lib.listToAttrs (
          map (name: {
            name = "tests-${name}";
            value = runTests pkgs name;
          }) addons
        )
      );

      devShells = forAll (
        { system, pkgs }:
        {
          default = pkgs.mkShell {
            PRE_COMMIT_SHELL_HOOK = self.checks.${system}.pre-commit.shellHook;
            shellHook = "source scripts/shell-hook.sh";
            packages = [
              pkgs.neovim-unwrapped
              pkgs.stylua
              pkgs.luajitPackages.luacheck
              pkgs.lua-language-server
              pkgs.just
              pkgs.jq
              pkgs.gitleaks
              pkgs.pre-commit
              pkgs.nixfmt
              pkgs.statix
              pkgs.deadnix
              pkgs.shellcheck
              pkgs.shfmt
            ];
          };
        }
      );
    };
}
