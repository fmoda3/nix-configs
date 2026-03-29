{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "1651f7b917daae7534f34b6a2a32ed6f2a67b244";
    sha256 = "sha256-ieqTkB/Du25rtCRfu/UhEPAvMWU6PoXtfKo3p8k+y/o=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
