{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage (finalAttrs: {
  pname = "ccusage";
  version = "18.0.8";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${finalAttrs.version}.tgz";
    hash = "sha256-vcXpZ/ZdyS/v9oeCh79h7pS6pWMDGBqiV3DI8L5lBaA=";
  };

  npmDepsHash = "sha256-xVDxEejgwxl/KS8ItOYXwOIIvsyxUBoaBU+LSFe2R30=";
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
