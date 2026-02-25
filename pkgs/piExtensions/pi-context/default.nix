{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "7007cf5e28b852816e835e27e54f30925d4f0750";
    sha256 = "sha256-5tZNMMxbQ4ggo2zDPayi8e0lk4dUdl6m3En5s1TpToY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
