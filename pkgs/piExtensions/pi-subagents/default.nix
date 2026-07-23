{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "fe3679b3adbeb072a1e2e354cd31750a104de794";
    sha256 = "sha256-sOXjhHQjmuCLhRH2hwlU3M5/M3wKCTnZ2wac+3Nbb6M=";
  };

  npmDepsHash = "sha256-IJQw1j3DaJY0G/bOQNvwRm0lMUzY+7LIt5+8HQsySfc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
