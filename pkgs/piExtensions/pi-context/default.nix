{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "2026-03-05";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "a5062d1def8faec29eb84c4e9dc0b907452d479d";
    sha256 = "sha256-MfmZ7ckGzWZFu+wTuVJhyTCYotBMIyGZhAZNozRjFq8=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
