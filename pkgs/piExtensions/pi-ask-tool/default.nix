{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-ask-tool";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "devkade";
    repo = "pi-ask-tool";
    rev = "880643605c7027f0115cca94fbd599bf3d2ce374";
    sha256 = "sha256-bCkzjcM4eRA9B7k5e/WBJBfsFdqb1EHf8On1wZD0QBU=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
