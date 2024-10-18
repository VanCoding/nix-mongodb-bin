{
  lib,
  stdenv,
  autoPatchelfHook,
  openssl,
  curl,
  xz,
  url,
  sha256,
  version,
  ...
}:
stdenv.mkDerivation rec {
  pname = "mongodb";
  inherit version;

  src = builtins.fetchurl {
    inherit url sha256;
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    openssl
    curl
    stdenv.cc.cc
    xz
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libpcap.so.0.8" # Only used by mongoreplay
  ];

  installPhase = ''
    install -m755 -D -t $out/bin bin/*
  '';
  meta.mainProgram = "mongod";
}
