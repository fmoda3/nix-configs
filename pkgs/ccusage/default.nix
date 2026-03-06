{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage (finalAttrs: {
  pname = "ccusage";
  version = "18.0.9";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${finalAttrs.version}.tgz";
    hash = "sha256-3dIp3y1vHg2BI+aJZt2nDh8inAXgv8irvsQyOF7wnQc=";
  };

  npmDepsHash = "sha256-Mzx6+Axh7Ojc7nS4cJctpNAK0s0WwxHUpX7bJmvfLUo=";
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
