{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "2026-03-20";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "fe3d812bf2abce179f91a0e823d47bf4790c9bfe";
    sha256 = "sha256-T6mxfY4+uw22try2V4i9VdUYJDI0B5/hJ5in24vDA+4=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
