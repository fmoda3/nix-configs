{ lib
, stdenv
, fetchurl
, jdk17
, makeWrapper
, unzip
}:

stdenv.mkDerivation rec {
  pname = "kotlin-lsp";
  version = "0.252.17811";

  src = fetchurl {
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-${version}.zip";
    hash = "sha256-DziwCvttgfY9JS3HKaC8M6AJvv0RreqZABpSeX1nMYw=";
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
    
    # Create wrapper script that points to the kotlin-lsp.sh script
    makeWrapper $out/share/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp \
      --set JAVA_HOME ${jdk17}
    
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
