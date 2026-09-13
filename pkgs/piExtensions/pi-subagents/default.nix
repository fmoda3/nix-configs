{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "940406c0d48890060d1f5f5280925c8f5a5c7389";
    sha256 = "sha256-NK+sU+rJ2clb+8XLds+gL9FHnQo7okphuj/JtFEcUcc=";
  };

  npmDepsHash = "sha256-Bto6gZcATd4R2ilK4fYlYzfiVaToLxR/6uCPSPqTuuI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
