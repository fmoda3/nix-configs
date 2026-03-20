{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-teams";
  version = "2026-03-20";

  src = fetchFromGitHub {
    owner = "burggraf";
    repo = "pi-teams";
    rev = "24596c922e832262626ab199fb3b42b3c42298d2";
    sha256 = "sha256-FHKHJ0o6zr+jhS5yyuoosmoWBZO4wRO0dHKOo3Hu9+k=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
