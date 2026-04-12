{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "244d2ef9c8a55b2b2cdd80386aa400316a3f3ffd";
    sha256 = "sha256-oG77cTIuc4alIERAKWBk2zCn74Z3AEFeueCsuX2ehOs=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
