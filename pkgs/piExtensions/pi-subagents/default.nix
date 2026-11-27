{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d164d844cea42af7651204b4efc80693fb271eaf";
    sha256 = "sha256-hgr5ppvBLaOSH66XQEiEqnprZiNqaXCoHOPrY7mvnM4=";
  };

  npmDepsHash = "sha256-iUL7l5zEKAbkDPKf7ZbhWyQd/5xUgqw3+OpkLTMG1Yk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
