{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-context";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "c782db0d88aaef1793cf9bbf815c7ad72b4acac7";
    sha256 = "sha256-T2vl7T+vJXxPqP8DO+ExlbP3rfohDQ+Ex10ETq/IpaM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
