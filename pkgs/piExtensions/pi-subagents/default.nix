{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0295a4e158168e8d9277658be6f04a5c2440bf5e";
    sha256 = "sha256-f1IWLS42CLs55lalq/vYVYDHCajJxKSh1+YlC5wJbTw=";
  };

  npmDepsHash = "sha256-c67CG1E4RDFxX9tpSGTBVQ8D1PWp4G+Zw+DQbNj/4Jg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
