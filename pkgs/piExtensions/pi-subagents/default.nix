{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7c98a69694e14cb9e1c81dd4c7a11a017d756aea";
    sha256 = "sha256-WsutSKHbzB5EQyVo++M4Y2i7RkN7fHiRDcPmi3a9UpI=";
  };

  npmDepsHash = "sha256-jL9QA5z18hQdcGtcawa78XC09Xg3tr/O9T7TOrmptiQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
