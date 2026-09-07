{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-07";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "56f247ac86169cfffa1af9a4c07997c33804bf9a";
    sha256 = "sha256-JMkFDTry8DFX149O7/rmzZLn3MAijUPXIbjjFGmJe5Y=";
  };

  npmDepsHash = "sha256-9ELFScZJI4mxupnvvAeUzG1ESBEUdYLOTqeDrLOmmCk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
