{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "0.2.24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "aed65b62e101f146532ae5156a30f9950f4d477d";
    sha256 = "sha256-7PIWXW4lazsy0jPh2LpLnSvxVJcWI1LbY56Qh024s5E=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
