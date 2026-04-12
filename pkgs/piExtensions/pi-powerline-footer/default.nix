{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-powerline-footer";
  version = "2026-04-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-powerline-footer";
    rev = "f442b0fdf067e71138f71eb025fe9004ceb3d194";
    sha256 = "sha256-l8f+SaNq3qDP/z+TOGSxXADU7vwp5gT9KVhmIjwTkTw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
