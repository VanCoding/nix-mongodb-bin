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
          releasesForSystem = builtins.filter (release: builtins.hasAttr system release.platforms) releases;

          # [{names = ["8-0-0" "8-0" "8"]; package = <derivation>;} {names = ["8-0-1"]; package = <derivation>;}]
          packagesWithNames = builtins.map (
            release:
            let
              nixpkgsVersion = if release.openssl == "3.0" then pkgs else pkgs-openssl_1_1;
              variant = builtins.elemAt release.platforms.${system} 0;
              package = nixpkgsVersion.callPackage ./mongodb.nix {
                version = builtins.elemAt release.names 0;
                inherit (variant) url sha256;
                openssl =
                  if release.openssl == "1.0" then
                    nixpkgsVersion.openssl_1_0_2
                  else if release.openssl == "1.1" then
                    nixpkgsVersion.openssl_1_1
                  else
                    nixpkgsVersion.openssl;
              };
            in
            {
              names = release.names;
              inherit package;
            }
          ) releasesForSystem;

          # { "8-0-0" = <derivation>; "8" = <derivation>; default = <derivation>; }
          versions =
            (lib.mergeAttrsList (
              builtins.concatMap (
                package:
                builtins.map (name: {
                  "${name}" = package.package;
                }) package.names
              ) packagesWithNames
            ))
            // {
              default = (builtins.elemAt packagesWithNames 0).package;
            };
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
