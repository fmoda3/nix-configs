{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "105c1399d36517292cc7dbe1f56f4724de39bd10";
    sha256 = "sha256-jbyEagH2RehWsQ8HZW19v3jxEmnsDqMFwolM8SGVfMo=";
  };

  npmDepsHash = "sha256-IJQw1j3DaJY0G/bOQNvwRm0lMUzY+7LIt5+8HQsySfc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
