{ lib
, buildNpmPackage
, fetchzip
}:

buildNpmPackage (finalAttrs: {
  pname = "ccusage";
  version = "20.0.9";

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${finalAttrs.version}.tgz";
    hash = "sha256-4KSCxiUbtg1lzZcRVUnEbeWexEI/C2F2Z+znR0uYKfI=";
  };

  npmDepsHash = "sha256-aQvBQYpbNspohLL8wMRxic8vUc8IUlbFkJM1PpK6EBs=";
  forceEmptyCache = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin $out/lib/node_modules/ccusage
    cp -r . $out/lib/node_modules/ccusage/

    # The JS launcher attempts to chmod the native optionalDependency at runtime
    # if it is not executable. Make it executable during the build instead,
    # since the Nix store is read-only at runtime.
    find $out/lib/node_modules/ccusage/node_modules/@ccusage -path '*/bin/ccusage*' -type f -exec chmod +x {} \;
    
    # Create symlink for the binary
    ln -s $out/lib/node_modules/ccusage/dist/cli.js $out/bin/ccusage
    chmod +x $out/bin/ccusage
    
    runHook postInstall
  '';

  meta = {
    description = "Analyze coding (agent) CLI token usage and costs from local data";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = lib.licenses.mit;
    mainProgram = "ccusage";
    maintainers = [ ];
  };
})
