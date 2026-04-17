{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "51bfd708bc9f40a5aa46dc3690d416b9af0a2a2b";
    sha256 = "sha256-Qaqdn6jGU5ryu2zjAiE/icKjo+6Q/FbRL+5SbA9umeY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
