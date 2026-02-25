{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "1281c04d91f39103ce4ae83a2ed66553179fbb6a";
    sha256 = "sha256-p18RBQl/2YIZkY7EwPDeHaOrhWkCcyBe42efyQ90KnA=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
