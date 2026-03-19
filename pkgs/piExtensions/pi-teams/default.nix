{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-teams";
  version = "2026-03-19";

  src = fetchFromGitHub {
    owner = "burggraf";
    repo = "pi-teams";
    rev = "1d61307fa59db72bf40be34bda018e2a2b20fe5c";
    sha256 = "sha256-OhaaRuFPCcmibzgzS/uAa+q0TWi0+cyhhPF/7YKHYKM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
