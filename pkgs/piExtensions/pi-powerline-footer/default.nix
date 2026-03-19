{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "81f96e0de651fc6e0ea0e21cc825f6803715eca4";
    sha256 = "sha256-ET8RxPKQH/WI+ES15F7DF/R0HP3Jvn0X0mkBnPLS2Co=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
