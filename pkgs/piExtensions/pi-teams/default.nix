{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-teams";
  version = "0.9.8";

  src = fetchFromGitHub {
    owner = "burggraf";
    repo = "pi-teams";
    rev = "89bccde903bd3c9fc849e00b25b9fc1c86f6e2f5";
    sha256 = "sha256-awfCnc/V3XyYkW19IPqp/FjWLIKk30wZfFrrzNOHE8s=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
