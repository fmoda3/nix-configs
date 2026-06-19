{ lib
, stdenv
, fetchurl
, makeWrapper
, unzip
}:

let
  # Define binary information for each platform
  version = "262.8190.0";
  sources = {
    "aarch64-darwin" = {
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}-aarch64.sit";
      sha256 = "sha256-4gGDJieEu35mXOGupIVYcqixbyEeu0eNRSdzVTcy2fs=";
    };
    "x86_64-darwin" = {
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}.sit";
      sha256 = "sha256-84Ra6e44wi715DY5DYaj2Qj3cHPpZn+mQ6WuCVfBlyg=";
    };
    "x86_64-linux" = {
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}.tar.gz";
      sha256 = "sha256-i0xw6VBlQg54Z8mar58Y4LTnYxHsRT5MGjnj9q53TL8=";
    };
    "aarch64-linux" = {
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}-aarch64.tar.gz";
      sha256 = "sha256-w+3VnvNKf6pNBPNRevt6kysZw/nPF9GhTp2hewtUQK0=";
    };
  };

  # Select the appropriate source for the current system
  selectedSource = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  src = fetchurl {
    inherit (selectedSource) url sha256;
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  unpackPhase = ''
    runHook preUnpack

    case "${selectedSource.url}" in
      *.tar.gz) tar -xzf $src ;;
      *) unzip $src ;;
    esac

    runHook postUnpack
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out/bin $out/share/kotlin-lsp
    
    # Copy all files to share directory
    cp -r kotlin-server-${version}/* $out/share/kotlin-lsp/

    # Make the server executable and bundled Java executable runnable.
    chmod +x $out/share/kotlin-lsp/bin/intellij-server
    ${if stdenv.hostPlatform.isDarwin then ''
      chmod +x $out/share/kotlin-lsp/jbr/Contents/Home/bin/java
    '' else ''
      chmod +x $out/share/kotlin-lsp/jbr/bin/java
    ''}

    # Create wrapper script that points to the standalone server executable.
    makeWrapper $out/share/kotlin-lsp/bin/intellij-server $out/bin/kotlin-lsp
    
    runHook postInstall
  '';

  meta = {
    description = "Kotlin Language Server Protocol implementation";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    license = lib.licenses.asl20;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "kotlin-lsp";
  };
}
