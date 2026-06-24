{ lib
, stdenv
, buildNpmPackage
, nodejs
, makeWrapper
, cacert
, playwright-driver
}:

let
  pname = "idp-cli";
  version = "0.2.0";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/idp-cli.git";
    rev = "e8f84196d370689673a5688bdd8273ae83f0fa83";
    ref = "main";
    narHash = "sha256-AYBF1T34c9T5E5BTwtriTuVvHIn9GjzdfOMrjkFgW8Y=";
  };

  # The OpenAPI codegen (`npm run generate`) pulls schemas from the internal
  # preprod schema registry, so it cannot run inside the normal (network-less)
  # build sandbox. We run it in a fixed-output derivation, which is allowed
  # network access. This requires Toast VPN connectivity at build time and the
  # output hash will drift whenever the upstream schemas change.
  generated = stdenv.mkDerivation {
    name = "${pname}-generated";
    inherit src;

    nativeBuildInputs = [ nodejs cacert ];

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      npm ci --ignore-scripts --no-audit --no-fund
      npm run generate
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r src/elevations/generated $out/elevations
      cp -r src/svcmgmt/generated $out/svcmgmt
      cp -r src/tuning-advisor/generated $out/tuning-advisor
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    # Regenerate (VPN required) when upstream schemas change:
    #   nix build .#... 2>&1 | grep 'got:'
    outputHash = "sha256-ZT7T4gFtrvgVsTqptvZTiuEeDDUawEWPUUQ8cyjXQj0=";
  };
in
buildNpmPackage {
  inherit pname version src;

  npmDepsHash = "sha256-dydPbc6cn5PFTD9myMmeEbmucyNTXbAVt9sbbYleiY8=";

  # The postinstall script downloads a Chromium browser, which fails in the
  # sandbox. Skip lifecycle scripts and provide the browser from nixpkgs at
  # runtime via PLAYWRIGHT_BROWSERS_PATH instead.
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  # Drop the pre-generated OpenAPI client into place, then build offline so we
  # do not re-trigger the network codegen.
  preBuild = ''
    cp -r ${generated}/elevations src/elevations/generated
    cp -r ${generated}/svcmgmt src/svcmgmt/generated
    cp -r ${generated}/tuning-advisor src/tuning-advisor/generated
    chmod -R u+w src
  '';

  npmBuildScript = "build:offline";

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev --ignore-scripts

    mkdir -p $out/bin $out/lib/node_modules/idp-cli
    cp -r dist node_modules package.json skills $out/lib/node_modules/idp-cli/

    makeWrapper ${nodejs}/bin/node $out/bin/idp \
      --add-flags "$out/lib/node_modules/idp-cli/dist/index.js" \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers} \
      --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true

    runHook postInstall
  '';

  meta = {
    description = "CLI for Toast IDP builds, logs, test results, and auto-elevations";
    mainProgram = "idp";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
