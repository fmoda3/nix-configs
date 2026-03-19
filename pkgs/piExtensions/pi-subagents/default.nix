{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "19623536f003fa96423113a9e2c337c9632122c3";
    sha256 = "sha256-wtc2UHnvDcKTTT4R0BjChoYilux6MCXbs4EmR6z1TSQ=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
