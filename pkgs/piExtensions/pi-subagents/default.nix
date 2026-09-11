{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "fe2a333b15f184883e2dc28c6ad8d9e2db5b6d2f";
    sha256 = "sha256-X7AFWzJSeQnIO3YHQORxDQDWs8hI3FJOvEu2joKRkwM=";
  };

  npmDepsHash = "sha256-Bto6gZcATd4R2ilK4fYlYzfiVaToLxR/6uCPSPqTuuI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
