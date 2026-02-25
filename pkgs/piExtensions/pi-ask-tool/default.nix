{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-ask-tool";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "devkade";
    repo = "pi-ask-tool";
    rev = "ac85cb0a29424e20d68f90dba9a493be7054ba4f";
    sha256 = "sha256-HN2pOkGpWxmXLYhp47hX955u8FeGeDrov9Eo/n3PNeU=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
