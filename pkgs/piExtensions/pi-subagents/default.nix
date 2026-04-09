{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "2f931d42624aa26693bf33f7cfceb76b28c34fdb";
    sha256 = "sha256-y3XhrMsX3I05hwta4X83H3V3Nu3Br6Anxbt7rtJ+p/o=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
