{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "0e40cfe8482a2e82672e49c8373b31684f918ced";
    sha256 = "sha256-GppOFqYvc24WuwsH6xLjxuCoB1sOAz3jkGh/MIYqTsQ=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
