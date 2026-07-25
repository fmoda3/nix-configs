{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "6455e6a73c730a8899802792a098a98db4971949";
    sha256 = "sha256-uQlaSjB2UK2QMQgJuGv4B6OiyXcyLfCmcIF4NQUNym4=";
  };

  npmDepsHash = "sha256-t+6/38eTmmC0gymmeX9QK5zKbRILtXNGHq/YmtNmheU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
