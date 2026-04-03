{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-04-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "16cec1fb981a51f63362bbb38c3238feec7b36c7";
    sha256 = "sha256-t4gxsjvRS8hoE09/CLFhItO8EaimELWqY3Yp16HLxQM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
