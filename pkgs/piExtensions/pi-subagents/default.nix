{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b0e3a480e9dfe45694de7522fc256f397225462b";
    sha256 = "sha256-2ogJjTsXR3HN17O8wuDOKx3wZURu5DyrEbyxuiF+qs0=";
  };

  npmDepsHash = "sha256-Bto6gZcATd4R2ilK4fYlYzfiVaToLxR/6uCPSPqTuuI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
