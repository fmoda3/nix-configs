{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "91ce1a47868be1b1d5a080052ede097f25e3042a";
    sha256 = "sha256-W4OtZeQdT+CE4ZE/C6QusE2zW65CW/kTuVFJtbGeb1g=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
