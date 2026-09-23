{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "68cea36fb85367ac36d0f2e752d21d24393ce234";
    sha256 = "sha256-q5DJLQej7Ge9+PDvwtKAVc/1L8qeKRP49Kw0yP0ZZM8=";
  };

  npmDepsHash = "sha256-iphThPMza97zUMs+d2hWuPYrfYUBX+Dwhp8StgHcx/g=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
