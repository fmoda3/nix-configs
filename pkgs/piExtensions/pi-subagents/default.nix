{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "49d1fb5f57fe4ae63cca6c0b59efdbc4a8661322";
    sha256 = "sha256-qGZKBxnLn520YvCvsM3FuMGKEVJXKoXzxqjZz5VwWio=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
