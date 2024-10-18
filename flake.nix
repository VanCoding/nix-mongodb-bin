{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        { config, pkgs, ... }:
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = [
              nixfmt-rfc-style
              bun
            ];
          };
          packages.updateReleases = writeShellApplication {
            name = "update-releases";
            runtimeInputs = [ bun ];
            shell = ''
              bun ./update-releases.sh
            '';
          };
        };
    };
}
