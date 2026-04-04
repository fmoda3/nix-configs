{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-04-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "41ff830f294ae203064f1f6ac433f5306a11b74c";
    sha256 = "sha256-/oxRdFPmtyB+UQei1dL9n5P/+pBVcGZAPg/nrtdFu70=";
  };

  npmDepsHash = "sha256-6dw9Wbxnc2HXRDl9Aw4YYV2lDplJcWiJa16C6Kz2WOI=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
