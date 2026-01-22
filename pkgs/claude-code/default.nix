{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, procps
, bubblewrap
, socat
,
}:

let
  version = "2.1.15";

  # Map Nix system to the URL components used by the distribution
  platformInfo = {
    "aarch64-darwin" = {
      os = "darwin";
      arch = "arm64";
      hash = "sha256-zGJ8DvWuGSwF0ALyc+Y32GdpIJC9I+/9XvUgaQ25XnE=";
    };
    "x86_64-darwin" = {
      os = "darwin";
      arch = "x64";
      hash = "sha256-3fCDEsfIDREavjmPjBtW+VRFpVDNZOEbsz7kV3uChkg=";
    };
    "x86_64-linux" = {
      os = "linux";
      arch = "x64";
      hash = "sha256-N/jodLjQfztgortHoQEDSDfR4zM+sRVS0JMteEQllJQ=";
    };
    "aarch64-linux" = {
      os = "linux";
      arch = "arm64";
      hash = "sha256-IKUgJWt4r/VtJz1hhsl5ZRHgQahQ/m7K6be3FX45lVQ=";
    };
  };

  platform = platformInfo.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/${version}/${platform.os}-${platform.arch}/claude";
    inherit (platform) hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  # autoPatchelfHook needs these for Linux
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/claude

    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --unset DEV \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            # claude-code uses [node-tree-kill](https://github.com/pkrumins/node-tree-kill) which requires procps's pgrep(darwin) or ps(linux)
            procps
          ]
          # the following packages are required for the sandbox to work (Linux only)
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }

    runHook postInstall
  '';

  # Skip version check since the binary outputs version differently
  doInstallCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
