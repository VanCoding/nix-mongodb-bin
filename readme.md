# nix-mongodb-bin

This flake patches the official mongodb binaries in all versions.
The goal is to make this compatible with as much versions of nixpkgs as possible, so that overriding it is not a problem.

## How to use

```
# latest
nix run github:VanCoding/nix-mongodb-bin# -- --version

# major
nix run github:VanCoding/nix-mongodb-bin#8 -- --version

# minor
nix run github:VanCoding/nix-mongodb-bin#8-0 -- --version

# patch
nix run github:VanCoding/nix-mongodb-bin#8-0-0 -- --version
```

## WARNING

Please note that not older versions require unsafe OpenSSL versions. **DO NOT USE THESE IN PRODUCTION**
