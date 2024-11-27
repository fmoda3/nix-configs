{ lib
, pkgs
, nodejs
, buildNpmPackage
, fetchFromGitHub
, stdenvNoCC
}:
let
  version = "0.122.0";
  repoSrc = fetchFromGitHub {
    owner = "koush";
    repo = "scrypted";
    rev = "v${version}";
    hash = "sha256-hKspvYn1GUvuLbQGiRRM+6IYbEQJI8ieelQppqkF2zE=";
  };
  node-addon-api = stdenvNoCC.mkDerivation rec {
    pname = "node-addon-api";
    version = "8.2.2";
    src = fetchFromGitHub {
      owner = "nodejs";
      repo = "node-addon-api";
      rev = "v${version}";
      hash = "sha256-/xOKTaMOqzgn25O0L/jASP1g6AwThXq297dX1/OJLkc=";
    };
    installPhase = ''
      mkdir $out
      cp -r *.c *.h *.gyp *.gypi index.js package-support.json package.json tools $out/
    '';
  };
in
buildNpmPackage {
  pname = "scrypted";
  inherit version;
  src = "${repoSrc}/server";

  npmDepsHash = "sha256-rtdnl6KlFwihe/z8AlHo8Fveovizd1hj/7kl98FmfpA=";

  makeFlags = [
    "CXXFLAGS=-I${node-addon-api}/include/node"
  ];

  inherit nodejs;

  makeCacheWritable = true;
  nativeBuildInputs = with pkgs; [
    python3
    node-addon-api
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    xcbuild
  ];

  meta = {
    description = "A home video integration and automation platform";
    homepage = "https://www.scrypted.app/";
    license = lib.licenses.isc;
    mainProgram = "scrypted-serve";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
