{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-plan";
  version = "2026-02-24";

  src = fetchFromGitHub {
    owner = "devkade";
    repo = "pi-plan";
    rev = "da5226a18b182641cfbfbae7912ff52638cccc67";
    sha256 = "sha256-m4zyK0LiBj8nYHe+hADmmsSHqnBqIUq2c50yiv7CVf0=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
