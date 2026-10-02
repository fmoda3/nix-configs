{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "ad56bf92fe01a2a5abd962938c619eb2a22ca47d";
    sha256 = "sha256-PaM7Rlupg24ZTfUKvqHtDZHR8BPuvVpMcZ8BVDgC/XU=";
  };

  npmDepsHash = "sha256-aasmHlWxGnSpRTKSvPKBHQ5DxlZusJILAT/7xGerYng=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
