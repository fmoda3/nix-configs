{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage rec {
  pname = "sequential-thinking-mcp";
  version = "0.6.2";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-sequential-thinking/-/server-sequential-thinking-${version}.tgz";
    hash = "sha256-U21rDtEpHYv+YPOs31AuGoTahR8QklNY4i0ySKWkX8U=";
  };

  npmDepsHash = "sha256-DeC170NHQC7RP5JaGLl37vckz4hrLgT5cCX2Q+o6rSo=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  dontNpmInstall = true;

  buildPhase = '''';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib/node_modules/@modelcontextprotocol/server-sequential-thinking
    cp -r * $out/lib/node_modules/@modelcontextprotocol/server-sequential-thinking/
    
    mkdir -p $out/bin
    makeWrapper ${nodejs_20}/bin/node $out/bin/sequential-thinking-mcp \
      --add-flags "$out/lib/node_modules/@modelcontextprotocol/server-sequential-thinking/dist/index.js"
    
    runHook postInstall
  '';

  meta = {
    description = "MCP server for sequential thinking and problem solving";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-sequential-thinking";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
