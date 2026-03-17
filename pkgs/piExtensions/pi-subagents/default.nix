{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-17";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f974c59da415c8a617773c3ca52a80fc61e05e7f";
    sha256 = "sha256-DLIxGJAs9PY4uQb42j9rW7jDh0fn8gtL+jFtt8BoR0c=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
