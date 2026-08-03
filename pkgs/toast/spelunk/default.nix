{ buildNpmPackage
, nodejs
, makeWrapper
, playwright-driver
}:

buildNpmPackage {
  pname = "spelunk";
  version = "2026-07-13";

  src = fetchGit {
    url = "git@github.toasttab.com:cakeface/spelunk.git";
    rev = "cafd846e937afd38b880a4fed1477fb59ad74ee9";
    ref = "main";
    narHash = "sha256-oZy2tQG25YY/cqTFfwlSWibqKg7Dx4ltPklBNhx38MQ=";
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

    makeWrapper ${nodejs}/bin/node $out/bin/spelunk \
      --add-flags "$out/lib/node_modules/spelunk/dist/index.js" \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers} \
      --set PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true

    runHook postInstall
  '';

  meta = {
    description = "CLI for running Splunk searches against Toast's Splunk Cloud instance";
    mainProgram = "spelunk";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
  };
}
