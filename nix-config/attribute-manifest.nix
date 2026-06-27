# Installation: nix-env --install --remove-all --file ./nix-config/attribute-manifest.nix
#
# To specify package versions, you can use overrideAttrs:
#   (pkgs.bun.overrideAttrs (old: { version = "1.3.2"; }))
#
{ pkgs ? import <nixos-unstable> {} }:

[
  pkgs.backrest
  pkgs.bun
  pkgs.claude-code
  pkgs.devenv
  pkgs.gh
  pkgs.hello
  pkgs.kitty
  pkgs.opencode
  pkgs.pnpm
  pkgs.rclone
  pkgs.restic
  pkgs.scrcpy
  pkgs.tinymist
  pkgs.uv
]
