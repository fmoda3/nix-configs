{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7848f9f3b9f27736276c25131cdca210979bf22d";
    sha256 = "sha256-MkYy0OlrlB0Vlod3Ntdps2gLsikrZ8ynzulpSJeG/2c=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
