{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-04-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "d351b6d134f2ff4ec6f35454927629e8b6ab316c";
    sha256 = "sha256-s9XWte5wfMnD77Jx7CzRycl76M9SR82zb4Lio9XeO3M=";
  };

  npmDepsHash = "sha256-p0UyUcK7S9BWQtuarEMUOfvE+UXwIj5IJWZFFg0FDWo=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
