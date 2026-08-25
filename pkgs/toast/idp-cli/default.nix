{ stdenv
, buildNpmPackage
, nodejs
, makeWrapper
, cacert
, playwright-driver
}:

let
  pname = "idp-cli";
  version = "2026-08-18";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/idp-cli.git";
    rev = "d37e9d7dde1a7cead73f965d96e8c661f22694a9";
    ref = "main";
    narHash = "sha256-zr+FiRnAkm8l2l8u2EAUmsAn/zz3cclEAsCI/xgXgbA=";
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

  npmDepsHash = "sha256-R6jQa/IEZulC7eRhCnqvtyI1E0KFcRkcBynXPY040HU=";

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

    # The bundled playwright-core pins exact browser revisions (e.g.
    # chromium-1217), while nixpkgs' playwright-driver ships the revisions of
    # its own playwright version (e.g. chromium-1228). Expose the nix browsers
    # under the revision names the bundled playwright looks for.
    browsersDir=$out/lib/node_modules/idp-cli/playwright-browsers
    mkdir -p $browsersDir
    for d in ${playwright-driver.browsers}/*; do
      ln -s "$d" "$browsersDir/$(basename "$d")"
    done

    ${nodejs}/bin/node -e '
      const fs = require("fs");
      const path = require("path");
      const dir = process.argv[1];
      const browsers = JSON.parse(fs.readFileSync(process.argv[2], "utf8")).browsers;
      const present = fs.readdirSync(dir);
      for (const b of browsers) {
        // playwright maps e.g. "chromium-headless-shell" -> "chromium_headless_shell-<rev>"
        const base = b.name.replace(/-/g, "_");
        const want = base + "-" + b.revision;
        if (present.includes(want)) continue;
        const have = present.find(d => new RegExp("^" + base + "-[0-9]+$").test(d));
        if (!have) continue;
        fs.symlinkSync(have, path.join(dir, want));
        console.log("playwright: aliased " + want + " -> " + have);
      }
    ' "$browsersDir" \
      "$out/lib/node_modules/idp-cli/node_modules/playwright-core/browsers.json"

    makeWrapper ${nodejs}/bin/node $out/bin/idp \
      --add-flags "$out/lib/node_modules/idp-cli/dist/index.js" \
      --set PLAYWRIGHT_BROWSERS_PATH "$browsersDir" \
      --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true

    runHook postInstall
  '';

  meta = {
    description = "CLI for Toast IDP builds, logs, test results, and auto-elevations";
    mainProgram = "idp";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
