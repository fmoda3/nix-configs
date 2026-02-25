{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "bb2b3492216354fb48f1deff212fd39e5cdc6f65";
    sha256 = "sha256-/7RcwsplwMqfx/9gzKRs7qXFl8muyc1vR7v0GN0y+rg=";
  };

  npmDepsHash = "sha256-ME9AQknl35IHlqLXOUmP6GRCW5sxqMQTzym0XILAAV8=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
