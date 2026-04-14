{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-14";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "fb21a75bb321eb9bee3cb9097d78a1e3003c4933";
    sha256 = "sha256-LNa4KIpD5RXOgTdlox39vKJuws37VB236vJyelG/yhc=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
