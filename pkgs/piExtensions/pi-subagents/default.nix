{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "869a457ef76a0e900213a8fef562ba13c3a3937c";
    sha256 = "sha256-uNB1aR6T/iNlhGEwlD/YOTz6IbHEo3kcgXXYsF0zD0o=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
