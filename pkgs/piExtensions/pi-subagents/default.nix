{ lib
, stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "aba3820f23e24d5a3f1b12f20feae03329f2ffc4";
    sha256 = "sha256-ZlRXoeBza6KnZhkPdTBbrSlg+AO9hNRTfsCx19Y4x8w=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
