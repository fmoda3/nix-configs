{ lib
, stdenv
, bun
, nodejs_22
, fetchFromGitHub
, fetchurl
, importNpmLock
, makeBinaryWrapper
, autoPatchelfHook
, libxcb
, versionCheckHook
, writableTmpDirAsHomeHook
, fd
, ripgrep
, wl-clipboard
, xclip
, darwin
,
}:
let
  nativePlatform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  nativeArch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  nativePath = "native/${nativePlatform}/prebuilds/${nativePlatform}-${nativeArch}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "pi-coding-agent";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-lwjspkMGrW+8Fl/yBEDEFsHZJA57OKOhmVQmi6zfej4=";
  };

  # Use the release's content-addressed, typed catalog rather than generated
  # files from an npm release. Hydration and compilation remain offline.
  modelCatalog =
    let
      pin = lib.importJSON (finalAttrs.src + "/nix/model-catalog.json");
    in
    fetchurl {
      name = "pi-model-catalog.json";
      url = "https://pi.dev/api/models/revisions/${pin.revision}?types=chat,image,classifier";
      sha256 = lib.removePrefix "sha256-" pin.revision;
    };

  npmDeps = importNpmLock { npmRoot = finalAttrs.src; };
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [
    bun
    nodejs_22
    importNpmLock.npmConfigHook
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ darwin.sigtool ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    libxcb
  ];

  # Stripping a Bun executable can destroy its appended JavaScript bundle.
  dontStrip = true;

  # bun build --compile appends the JS bundle to the Mach-O after the linker
  # has signed it, leaving an ad-hoc signature that does not validate. macOS 27
  # AMFI rejects the mapping and SIGKILLs at exec. Re-sign after wrapping.
  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    codesign --force --sign - $out/bin/.pi-wrapped
  '';

  buildPhase = ''
    runHook preBuild

    node packages/ai/scripts/hydrate-model-catalog.ts ${finalAttrs.modelCatalog}
    npm run build:offline

    cd packages/coding-agent

    # Keep all entrypoints under this common root so embedded worker paths
    # match the specifiers used by the standalone runtime.
    bun build --compile --no-compile-autoload-bunfig \
      ./dist/bun/cli.js \
      ./src/utils/image-resize-worker.ts \
      ./src/extensions/codemode/worker.ts \
      --outfile dist/pi

    # Exercise the same compiled worker layout without credentials or a model.
    cp ${./packaging-smoke.ts} dist/bun/packaging-smoke.ts
    bun build --compile --no-compile-autoload-bunfig \
      ./dist/bun/packaging-smoke.ts \
      ./src/utils/image-resize-worker.ts \
      ./src/extensions/codemode/worker.ts \
      --outfile dist/packaging-smoke
    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      codesign --force --sign - dist/packaging-smoke
    ''}

    cd ../..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/pi-coding-agent
    install -Dm755 packages/coding-agent/dist/pi $out/bin/pi

    # Reuse upstream's complete built assets, not copy-binary-assets (which
    # currently omits the CSS/JS files required by HTML export).
    cp -r packages/coding-agent/dist/modes/interactive/theme $out/share/pi-coding-agent/
    cp -r packages/coding-agent/dist/modes/interactive/assets $out/share/pi-coding-agent/
    cp -r packages/coding-agent/dist/core/export-html $out/share/pi-coding-agent/
    cp -r packages/coding-agent/{docs,examples} $out/share/pi-coding-agent/
    cp packages/coding-agent/{package.json,CHANGELOG.md,README.md} $out/share/pi-coding-agent/
    cp node_modules/@silvia-odwyer/photon-node/photon_rs_bg.wasm $out/share/pi-coding-agent/

    # The native loader searches beside process.execPath, not PI_PACKAGE_DIR.
    mkdir -p $out/bin/${nativePath}
    cp packages/tui/${nativePath}/*.node $out/bin/${nativePath}/

    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath ([ fd ripgrep ] ++ lib.optionals stdenv.hostPlatform.isLinux [ wl-clipboard xclip ])} \
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

  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/pi --help > /dev/null

    # Keep all writes outside the source tree and never use the user's config.
    export PI_CODING_AGENT_DIR="$TMPDIR/pi-packaging-agent"
    mkdir -p "$PI_CODING_AGENT_DIR"
    printf '%s\n' \
      '{"type":"session","version":3,"id":"packaging-test","timestamp":"2026-01-01T00:00:00.000Z","cwd":"/tmp"}' \
      > "$TMPDIR/pi-packaging-session.jsonl"
    $out/bin/pi --export "$TMPDIR/pi-packaging-session.jsonl" "$TMPDIR/pi-packaging-session.html"
    test -s "$TMPDIR/pi-packaging-session.html"

    # Exercise native discovery in the actual wrapped CLI. A dummy DISPLAY
    # enables the Linux loader, but the check never accesses the clipboard.
    cp ${./native-helper-check.ts} "$TMPDIR/native-helper-check.ts"
    DISPLAY=:pi-packaging $out/bin/pi \
      --offline --mode rpc --no-session --no-extensions --no-skills \
      --no-prompt-templates --no-themes -e "$TMPDIR/native-helper-check.ts" \
      < /dev/null > "$TMPDIR/native-helper-check.log"
    grep -q PACKAGING_NATIVE_HELPER_OK "$TMPDIR/native-helper-check.log"

    PI_PACKAGE_DIR=$out/share/pi-coding-agent \
      packages/coding-agent/dist/packaging-smoke

    runHook postInstallCheck
  '';

  meta = {
    description = "Minimal terminal coding agent with read, bash, edit, write tools";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource binaryNativeCode ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "pi";
  };
})
