{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-31";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3f879722f96fdec19364ccd9a18f8176d797fedc";
    sha256 = "sha256-4W0n4qckCP5z6b9RXU36kgoY65w26h8/3gX1Cu5jcSk=";
  };

  npmDepsHash = "sha256-c67CG1E4RDFxX9tpSGTBVQ8D1PWp4G+Zw+DQbNj/4Jg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
