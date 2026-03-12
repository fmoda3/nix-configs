{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-notify";
  version = "2026-02-12";

  src = fetchFromGitHub {
    owner = "ferologics";
    repo = "pi-notify";
    rev = "a00d92f6a1c750e8f06665ca1c7f743d3f3af5fc";
    sha256 = "sha256-lQ2SOkeNB2wesquoztFaj1VUXZlDPnQhsrv03LaCK3E=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
