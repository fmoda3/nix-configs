{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage (finalAttrs: {
  pname = "ccusage";
  version = "18.0.5";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${finalAttrs.version}.tgz";
    hash = "sha256-i4UyRU7EA0PLduABnPGbcD8I06ZjmjwXCC77vtFM638=";
  };

  npmDepsHash = "sha256-C08Yub31utCsNxDvCc9YYoFTP9MWks0cTM0jc2dueUI=";
  forceEmptyCache = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin $out/lib/node_modules/ccusage
    cp -r . $out/lib/node_modules/ccusage/
    
    # Create symlink for the binary
    ln -s $out/lib/node_modules/ccusage/dist/index.js $out/bin/ccusage
    chmod +x $out/bin/ccusage
    
    runHook postInstall
  '';

  meta = {
    description = "Analyze your Claude Code token usage and costs from local JSONL files";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = lib.licenses.mit;
    mainProgram = "ccusage";
    maintainers = [ ];
  };
})
