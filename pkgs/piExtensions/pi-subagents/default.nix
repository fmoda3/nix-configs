{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "67193e56bb47802cd4b1a5db1e1197119993445f";
    sha256 = "sha256-RjBeqQzgXN0Dh2UHOQbY8NK1UbezSd06KnabX7OH4RY=";
  };

  npmDepsHash = "sha256-kJqaHv5+vHj8F1QpK9ocsoXetdCoTtqC8aEq92yvUKk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
