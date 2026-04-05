{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b5148abe4a81133658480fc1789efb78612eb0fa";
    sha256 = "sha256-4pz+/DvBPUakFn4Oe6ONYUT6ipGxJrb1uh7aFwyR9YM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
