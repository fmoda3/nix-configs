{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-03-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "31bc98bcee50e3c21283dc7db3cdf7bfbe757a13";
    sha256 = "sha256-ZWEuYtrFxwlsqtbZ2UV2LS0lVpQpAxje/LmBPWYvmcI=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
