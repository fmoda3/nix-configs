{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "32464332af4a0c256cde37f1401bfbd8b5f1262f";
    sha256 = "sha256-sd2bYvJ6rfU/+4TS6F9t4YIcVjNzgHeBKnVQmFu6RlM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
