{ stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  pname = "toastApiKeyHelper";
  version = "dev";

  src = fetchurl {
    url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/toastApiKeyHelper/dev/toastApiKeyHelper-darwin-arm64";
    sha256 = "sha256-TWX56ljL66eEGpXmHIwezOWPFKXaCGh9dxGc4Ku04vU=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/toastApiKeyHelper
    chmod +x $out/bin/toastApiKeyHelper

    runHook postInstall
  '';

  meta = {
    description = "Toast API Key Helper utility";
    platforms = [ "aarch64-darwin" ];
    mainProgram = "toastApiKeyHelper";
  };
}
