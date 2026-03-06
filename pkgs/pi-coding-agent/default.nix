{ lib
, stdenvNoCC
, bun
, nodejs_22
, fetchFromGitHub
, makeBinaryWrapper
, versionCheckHook
, writableTmpDirAsHomeHook
, cacert
, fd
, ripgrep
,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.56.3";

  src = fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QLNzIw/NrZC3nUtESUVp8eo0sUHR8CmLNp+PZmvRTc4=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      nodejs_22
      cacert
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      npm ci --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-Zu4H0TVDk0umC2zYalvoVtS9x3yZvTaoW3r6MYNtZRM=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs_22
    makeBinaryWrapper
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    export PATH="$PWD/node_modules/.bin:$PATH"

    # Build workspace dependencies in order
    cd packages/tui
    tsgo -p tsconfig.build.json
    cd ../ai
    tsgo -p tsconfig.build.json
    cd ../agent
    tsgo -p tsconfig.build.json

    # Build coding-agent
    cd ../coding-agent
    tsgo -p tsconfig.build.json
    chmod +x dist/cli.js

    # Build standalone binary with Bun
    bun build --compile ./dist/cli.js --outfile dist/pi

    # Copy binary assets alongside
    cp package.json dist/
    cp README.md dist/
    cp CHANGELOG.md dist/
    mkdir -p dist/theme
    cp src/modes/interactive/theme/*.json dist/theme/
    cp -r src/core/export-html dist/
    cp -r docs dist/
    cp -r examples dist/
    cp ../../node_modules/@silvia-odwyer/photon-node/photon_rs_bg.wasm dist/

    cd ../..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/pi-coding-agent

    install -Dm755 packages/coding-agent/dist/pi $out/bin/pi

    # Install runtime assets that the binary discovers via PI_PACKAGE_DIR
    cp -r packages/coding-agent/dist/theme $out/share/pi-coding-agent/
    cp -r packages/coding-agent/dist/export-html $out/share/pi-coding-agent/
    cp -r packages/coding-agent/dist/docs $out/share/pi-coding-agent/
    cp -r packages/coding-agent/dist/examples $out/share/pi-coding-agent/
    cp packages/coding-agent/dist/package.json $out/share/pi-coding-agent/
    cp packages/coding-agent/dist/photon_rs_bg.wasm $out/share/pi-coding-agent/
    cp packages/coding-agent/dist/CHANGELOG.md $out/share/pi-coding-agent/
    cp packages/coding-agent/dist/README.md $out/share/pi-coding-agent/

    # Bun binary looks for theme/ and export-html/ relative to dirname(process.execPath)
    ln -s $out/share/pi-coding-agent/theme $out/bin/theme
    ln -s $out/share/pi-coding-agent/export-html $out/bin/export-html

    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath [ fd ripgrep ]} \
      --set PI_PACKAGE_DIR $out/share/pi-coding-agent \
      --set PI_SKIP_VERSION_CHECK 1

    runHook postInstall
  '';

  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Minimal terminal coding agent with read, bash, edit, write tools";
    homepage = "https://github.com/badlogic/pi-mono";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "pi";
  };
})
