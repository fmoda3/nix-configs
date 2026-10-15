{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "475600bc8156bd620425f1956cb7b95c53ee4458";
    sha256 = "sha256-8n09hvNoJe9oGnmr3CQV5j9sYYAMQgt/bCR5KehXO38=";
  };

  npmDepsHash = "sha256-862hXsUJ7CSVSntkV1Iv4z5E2On8v5BJSbM9iIYe+GY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
