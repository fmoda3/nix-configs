{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0229884274b1932a500e8901af1f49eeef5fa938";
    sha256 = "sha256-x3DrZEsKk4yvW6tfCc++kPKuDrTO+Z6mcnmmBsj4Fwk=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
