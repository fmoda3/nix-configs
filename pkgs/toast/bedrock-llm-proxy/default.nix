{ stdenv
, fetchurl
}:

let
  # Define binary information for each platform
  version = "1.0.59";
  sources = {
    "aarch64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_1.0.59_darwin_arm64.tar.gz";
      sha256 = "sha256-uoFFBq/iTiuylQZuKtTIOAHtMn+Jwd2L9PDAww7BUpE=";
    };
    "x86_64-darwin" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_1.0.59_darwin_amd64.tar.gz";
      sha256 = "sha256-wW8MZtWoDPWie0wfubd8cYD9nrS5Bz0bEhikLGOXtJ8=";
    };
    "x86_64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_1.0.59_linux_amd64.tar.gz";
      sha256 = "sha256-DyVz/L0iGLoEHcU056nNp7H2HUw/3AW4Pq8dvJVT3Ks=";
    };
    "aarch64-linux" = {
      url = "https://artifactory.eng.toasttab.com/artifactory/go-binaries/bedrock-llm-proxy/${version}/bedrock-llm-proxy_toast-llm-utils_1.0.59_linux_arm64.tar.gz";
      sha256 = "sha256-4ZPcWdtHF/HzonUcW0hvvT2DOBo8ChGbFC8m5UfTlpI=";
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
