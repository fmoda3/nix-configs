{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "52ece5ad2c07988a67551acc53f8dc92160908b1";
    sha256 = "sha256-vxS7zpEZrH/mIWMem3q+okNp7aEABEbQ900YIIrz/OE=";
  };

  npmDepsHash = "sha256-9ELFScZJI4mxupnvvAeUzG1ESBEUdYLOTqeDrLOmmCk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
