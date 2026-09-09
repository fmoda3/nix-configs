{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "808387a206b668b590720050ae4f637d69b6b80c";
    sha256 = "sha256-5zmBLu+rLtLKR6TfJhxJ6cxVP8Zkj5VTWOAXdgOawes=";
  };

  npmDepsHash = "sha256-9ELFScZJI4mxupnvvAeUzG1ESBEUdYLOTqeDrLOmmCk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
