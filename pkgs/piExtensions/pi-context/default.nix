{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "7fd8752d05d98e4e38a7d0bc22de51d72d99f398";
    sha256 = "sha256-cbcXUSzZfAXupQ1fzsise4OXFwH1N2VAIA3jdDyLJ/U=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
