{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-openssl_1_1.url = "github:NixOS/nixpkgs/30d3d79b7d3607d56546dd2a6b49e156ba0ec634";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      nixpkgs-openssl_1_1,
      ...
    }:
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
          pkgs-openssl_1_1 = import nixpkgs-openssl_1_1 {
            inherit system;
            config = {
              permittedInsecurePackages = [
                "openssl-1.0.2u"
              ];
            };
          };
          availableReleases = lib.attrsets.filterAttrs (
            version: release: builtins.hasAttr system release.platforms
          ) releases;
          versions = (
            builtins.mapAttrs (
              version: systems:
              let
                release = availableReleases.${version};
                nixpkgsVersion = if release.openssl == "3.0" then pkgs else pkgs-openssl_1_1;
                variant = builtins.elemAt release.platforms.${system} 0;
              in
              nixpkgsVersion.callPackage ./mongodb.nix {
                inherit version;
                inherit (variant) url sha256;
                openssl =
                  if release.openssl == "1.0" then
                    nixpkgsVersion.openssl_1_0_2
                  else if release.openssl == "1.1" then
                    nixpkgsVersion.openssl_1_1
                  else
                    nixpkgsVersion.openssl;
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
                bun ./update-releases.ts
              '';
            };
          } // versions;
        };
    };
}
