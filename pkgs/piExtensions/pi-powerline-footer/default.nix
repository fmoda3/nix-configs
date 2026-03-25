{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "74713be60eeb8393b53d751e207d3bdc411e072f";
    sha256 = "sha256-EE3/8sWhNRbIpIiWjTMg2cqybkJRuTrrdP1gP5qlB1A=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
