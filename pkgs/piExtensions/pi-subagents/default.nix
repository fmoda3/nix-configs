{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "0.11.1";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "c8afe420ea4e9c0c99b22eceeda4248a0fde7139";
    sha256 = "sha256-Xrl5ueItr07gQSv825w3u1zXfRMDOjwn32PORL5+WW8=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
