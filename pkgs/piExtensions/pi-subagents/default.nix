{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "6f1027f7b353204579d50f1f5c90c47990215b26";
    sha256 = "sha256-wOrwvAtwGufjREFi9ng/nTgopZC1T8Lizaj1Vr620tk=";
  };

  npmDepsHash = "sha256-iphThPMza97zUMs+d2hWuPYrfYUBX+Dwhp8StgHcx/g=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
