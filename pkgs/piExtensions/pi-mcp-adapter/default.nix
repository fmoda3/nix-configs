{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-04-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "981b13490534b4abbe4396ed503842e94f0fac64";
    sha256 = "sha256-tCgn19vGwfvOgmk9WGFLkmSWltzJE1Z25QNzIfeJwwY=";
  };

  npmDepsHash = "sha256-sp1yphGR0P5BunmNGyyc67DXJG9DBuDvvbQp3fxG8Fs=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
