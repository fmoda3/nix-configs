{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "83be9c3de2cde1553c0269f383efc1eb1194dc8b";
    sha256 = "sha256-/l5CXGrA4ik3qpGBJKsjqeDL/esFu74mocBlq//WUMs=";
  };

  npmDepsHash = "sha256-rVMH0m5XkzL6lAXrzkn2ZphkEKkFoGJyz4n3648ekXU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
