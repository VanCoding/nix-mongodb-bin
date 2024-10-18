# nix-mongodb-bin

This flake patches the official mongodb binaries in all versions.
The goal is to make this compatible with as much versions of nixpkgs as possible, so that overriding it is not a problem.

## How to use

```
nix run github:VanCoding/nix-mongodb-bin#8-0-0 -- --version

```
