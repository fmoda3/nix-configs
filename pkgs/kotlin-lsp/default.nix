{ lib
, stdenv
, fetchurl
, makeWrapper
, unzip
}:

let
  # Define binary information for each platform
  version = "262.1817.0";
  sources = {
    "aarch64-darwin" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-aarch64.zip";
      sha256 = "0jnfy97bhysqdybmvx51ray6wl2advalls3ccmcnasygsxxlrqs6";
    };
    "x86_64-darwin" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-x64.zip";
      sha256 = "0phi5kds4xbb2b1yh6a037bp4kwnydnbzwdw2x22bdw30ih4pbnw";
    };
    "x86_64-linux" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.zip";
      sha256 = "0ismhk2aqa605l9xi2kf269gjli77mgqi744cp5nq1gln9kwlvys";
    };
    "aarch64-linux" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-aarch64.zip";
      sha256 = "01apjqyawywx7rizkx033j0wdddpwvk2f31ijr7xissq1vb7djbj";
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
    
    unzip $src
    
    runHook postUnpack
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out/bin $out/share/kotlin-lsp
    
    # Copy all files to share directory
    cp -r * $out/share/kotlin-lsp/

    # Make the shell script executable
    chmod +x $out/share/kotlin-lsp/kotlin-lsp.sh

    # Make the bundled Java executable (path differs between macOS and Linux)
    ${if stdenv.hostPlatform.isDarwin then ''
      chmod +x $out/share/kotlin-lsp/jre/Contents/Home/bin/java
    '' else ''
      chmod +x $out/share/kotlin-lsp/jre/bin/java
    ''}

    # Create wrapper script that points to the kotlin-lsp.sh script
    makeWrapper $out/share/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp
    
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
