{ buildNpmPackage
, nodejs
, makeWrapper
, playwright-driver
}:

buildNpmPackage {
  pname = "spelunk";
  version = "2026-08-20";

  src = fetchGit {
    url = "git@github.toasttab.com:cakeface/spelunk.git";
    rev = "5a44b7e94ba2d5e6231e8d9c06a990bcfce39b3b";
    ref = "main";
    narHash = "sha256-CahfM3odxh61GjCH+58yBmhF2am6ydTwSRXQhsMpZ2Y=";
  };

  npmDepsHash = "sha256-MJsRxV56EAssyhuF946KI+lFa0grqimsQ+G3qAtlBus=";

  # The postinstall script runs `npx playwright install chromium`, and the
  # `prepare` script runs husky; both fail in the sandbox. Skip lifecycle
  # scripts and provide the browser from nixpkgs at runtime via
  # PLAYWRIGHT_BROWSERS_PATH instead.
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev --ignore-scripts

    mkdir -p $out/bin $out/lib/node_modules/spelunk
    cp -r dist node_modules package.json $out/lib/node_modules/spelunk/

    # The bundled playwright-core pins exact browser revisions (e.g.
    # chromium-1217), while nixpkgs' playwright-driver ships the revisions of
    # its own playwright version (e.g. chromium-1228). Expose the nix browsers
    # under the revision names the bundled playwright looks for.
    browsersDir=$out/lib/node_modules/spelunk/playwright-browsers
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
      "$out/lib/node_modules/spelunk/node_modules/playwright-core/browsers.json"

    makeWrapper ${nodejs}/bin/node $out/bin/spelunk \
      --add-flags "$out/lib/node_modules/spelunk/dist/index.js" \
      --set PLAYWRIGHT_BROWSERS_PATH "$browsersDir" \
      --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true

    runHook postInstall
  '';

  meta = {
    description = "CLI for running Splunk searches against Toast's Splunk Cloud instance";
    mainProgram = "spelunk";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
