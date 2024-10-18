{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    inputs@{ flake-parts, ... }:
    let
      releases = builtins.fromJSON (builtins.readFile ./releases.json);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aaarch64-darwin"
      ];
      perSystem =
        {
          config,
          pkgs,
          system,
          lib,
          ...
        }:
        with pkgs;
        let
          availableReleases = lib.attrsets.filterAttrs (
            version: systems: builtins.hasAttr system systems
          ) releases;
          versions = (
            builtins.mapAttrs (
              version: systems:
              let
                variant = builtins.elemAt availableReleases.${version}.${system} 0;
              in
              callPackage ./mongodb.nix {
                inherit version;
                inherit (variant) url sha256;
              }
            ) availableReleases
          );
        in
        {
          devShells.default = mkShell {
            buildInputs = [
              nixfmt-rfc-style
              bun
            ];
          };
          packages = {
            updateReleases = writeShellApplication {
              name = "update-releases";
              runtimeInputs = [ bun ];
              text = ''
                bun ./update-releases.sh
              '';
            };
          } // versions;
        };
    };
}
