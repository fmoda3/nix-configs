{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "5748ebab4ca2c9614969b23dd8f87b872fc3833d";
    sha256 = "sha256-tLGGaMm8diie0ZNEb44ccrX8ZsKM7N/gGbEAgwlyhoA=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
