{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7e2794efba0b727af51d08c36614ea939f1a827b";
    sha256 = "sha256-cEWmT86AJAIsSWJWlP4eI8zub7L6dZWlYoMleZqNsms=";
  };

  npmDepsHash = "sha256-8/f62IizitxwVSAWOmWrPCoRBXjOj3JKtOHBUmpyyMg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
