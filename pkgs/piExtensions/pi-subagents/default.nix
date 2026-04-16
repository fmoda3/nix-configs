{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "24cda8de326b3c413cd1322699be52a5b60f0834";
    sha256 = "sha256-wwC+QnSADuvAfDRWpfLI8NDhFxWtNjSE7e0bepavR54=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
