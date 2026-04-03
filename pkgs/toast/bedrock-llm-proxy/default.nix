{ stdenv
, fetchurl
}:

let
  # Define binary information for each platform
  version = "1.0.93";
  sources = {
    "aarch64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_darwin_arm64.tar.gz";
      sha256 = "sha256-jjpZoSd05Tw/Jykd5iRPsGNaiC4X+iT+mp3NWrIbLvE=";
    };
    "x86_64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_darwin_amd64.tar.gz";
      sha256 = "sha256-FiqWcsGS4xRrSYrMl6UEoH2WNoJ64vsL+nN1xgKzLaI=";
    };
    "x86_64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_linux_amd64.tar.gz";
      sha256 = "sha256-w5F85LRfvZCzBt5LCh8dPceDuxa5FrKRFtxiXdwBKsw=";
    };
    "aarch64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_${version}_linux_arm64.tar.gz";
      sha256 = "sha256-l1FjtxXto/N111sFeSTAp+l2wskv9o4p/gAElWazplg=";
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
    cp toastApiKeyHelper $out/bin/toastApiKeyHelper
    cp toast-llm $out/bin/toast-llm
    chmod +x $out/bin/toastApiKeyHelper
    chmod +x $out/bin/toast-llm

    runHook postInstall
  '';

  meta = {
    description = "Toast API Key Helper utility";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
