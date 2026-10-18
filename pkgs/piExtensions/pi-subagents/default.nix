{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-17";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "1008e5993e90fcf13b815c97c15a0c54f7f6f116";
    sha256 = "sha256-Cpl2ikR14KMxwJEWPCTi17QpuFWy214Fwufc6XJpy6U=";
  };

  npmDepsHash = "sha256-XqdBigQ1lrHr9qmBi36lsAm8rtsY0jPBETrAISxJzyE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
