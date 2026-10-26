{
  writeShellApplication,
  coreutils,
  neovide,
  version,
}:
(writeShellApplication {
  name = "nvimx-remote";
  runtimeInputs = [
    coreutils
    neovide
  ];
  text = builtins.readFile ./nvimx-remote.sh;
}).overrideAttrs
  { inherit version; }
