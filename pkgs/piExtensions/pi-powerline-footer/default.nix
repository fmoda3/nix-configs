{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-04-14";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "7181211f03b0c0673e0482a7d6f5af8079191855";
    sha256 = "sha256-xf9KxVBueyMsDZOd7TAngCIgdUJm8AzDZs1q0+9nXfY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
