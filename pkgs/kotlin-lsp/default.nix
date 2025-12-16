{ lib
, stdenv
, fetchurl
, makeWrapper
, unzip
}:

let
  # Define binary information for each platform
  version = "261.13587.0";
  sources = {
    "aarch64-darwin" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-aarch64.zip";
      sha256 = "0v7fzfp6lc2gb0awnvd6lr31dwb8hj56j8vdw5pr1kr95fr2isnl";
    };
    "x86_64-darwin" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-x64.zip";
      sha256 = "18v40m6sfwizyldrgz3d68nchn69l6p4prb0c0i2rfly48kjz5x3";
    };
    "x86_64-linux" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.zip";
      sha256 = "1v43dvncm4jyf49r9yzzvk07aylv57lgrbi6pgd1zmmh1kkx43nw";
    };
    "aarch64-linux" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-aarch64.zip";
      sha256 = "0lfny6ll9dgfgwb4im1ys0di018xn157ypmr60n5wv701w0fpp6i";
    };
  };

  # Select the appropriate source for the current system
  selectedSource = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
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

    # Make the bundled Java executable
    chmod +x $out/share/kotlin-lsp/jre/Contents/Home/bin/java
    
    # Create wrapper script that points to the kotlin-lsp.sh script
    makeWrapper $out/share/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Kotlin Language Server Protocol implementation";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    license = licenses.asl20;
    platforms = platforms.all;
    mainProgram = "kotlin-lsp";
  };
}
