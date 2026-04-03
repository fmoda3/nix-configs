{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-teams";
  version = "2026-04-03";

  src = fetchFromGitHub {
    owner = "burggraf";
    repo = "pi-teams";
    rev = "965c02e2de9db77739f95766f5f66c86b4c272b0";
    sha256 = "sha256-vvTwFLRPVufnp0gxWtZlbUxC/dnQtj4TzretuR3ThaM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
