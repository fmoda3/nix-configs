{ stdenv
, fetchurl
}:

let
  # Define binary information for each platform
  version = "dev";
  sources = {
    "aarch64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/toastApiKeyHelper/${version}/toastApiKeyHelper-darwin-arm64";
      sha256 = "sha256-TWX56ljL66eEGpXmHIwezOWPFKXaCGh9dxGc4Ku04vU=";
    };
    "x86_64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/toastApiKeyHelper/${version}/toastApiKeyHelper-darwin-amd64";
      sha256 = "sha256-z/JcteQkWW/descmm6EyKUurG7QmzZlsnWgmGHZ7PM8=";
    };
    "x86_64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/toastApiKeyHelper/${version}/toastApiKeyHelper-linux-amd64";
      sha256 = "sha256-zI6GK/Rf3jqroh1czq0/nl8Ka2YEdGuK6QXstSGeg08=";
    };
    "aarch64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/toastApiKeyHelper/${version}/toastApiKeyHelper-linux-arm64";
      sha256 = "sha256-Xei5iOvVLqHBnyz3ZC12oZFhbQPNPmJMVWG1qA+PVBI=";
    };
  };

  # Select the appropriate source for the current system
  selectedSource = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "toastApiKeyHelper";
  inherit version;

  src = fetchurl {
    inherit (selectedSource) url sha256;
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
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
    mainProgram = "toastApiKeyHelper";
  };
}
