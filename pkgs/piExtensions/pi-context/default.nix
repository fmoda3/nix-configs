{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "4532bb60b29b37a64ce309c408e0263228ba88cb";
    sha256 = "sha256-kI7LfbqMc+Dt1Jp0hA9GTPhH98Di16VshoDINnkVA+s=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
