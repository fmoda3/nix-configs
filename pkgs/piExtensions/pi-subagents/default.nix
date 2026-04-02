{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e8be89f22e2ac01058d60face3b0a50a2ba96215";
    sha256 = "sha256-XZNm2EdvrWqMHPd/rbEwcFQ4dyy9KChWAuM0xhCiCxE=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
