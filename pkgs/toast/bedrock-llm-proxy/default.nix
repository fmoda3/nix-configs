{ stdenv
, fetchurl
}:

let
  # Define binary information for each platform
  version = "1.0.215";
  sources = {
    "aarch64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_darwin_arm64.tar.gz";
      sha256 = "sha256-jtvGK0qeFFt8QVeunv8TXllXpX86R8GazGtN+b85/TA=";
    };
    "x86_64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_darwin_amd64.tar.gz";
      sha256 = "sha256-U85ToMeAcfNRWj0J/JcpdyJ3/9bN+5O7HD2vMATL7h4=";
    };
    "x86_64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_linux_amd64.tar.gz";
      sha256 = "sha256-zdv4dLxn0drIEFnPgCSYw0GH4KpKqyTJ759gQCfVEto=";
    };
    "aarch64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_linux_arm64.tar.gz";
      sha256 = "sha256-SYBEdXCy6YBM4ZQj/nlsJ5EdWUBUaE5Eim0Y3GGtgMI=";
    };
  };

  # Select the appropriate source for the current system
  selectedSource = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "bedrock-llm-proxy";
  inherit version;

  src = fetchurl {
    inherit (selectedSource) url sha256;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp toast-llm $out/bin/toast-llm
    chmod +x $out/bin/toast-llm
    printf '#!/bin/sh\nexec "%s/bin/toast-llm" auth token "$@"\n' "$out" > $out/bin/toastApiKeyHelper
    chmod +x $out/bin/toastApiKeyHelper
    printf '#!/bin/sh\nexec "%s/bin/toast-llm" otel-headers "$@"\n' "$out" > $out/bin/otelHeadersHelper
    chmod +x $out/bin/otelHeadersHelper

    runHook postInstall
  '';

  meta = {
    description = "Toast API Key Helper utility";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
