{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "feb24a40273ff81ec8cefe5d0831fa7fdcc5e217";
    sha256 = "sha256-po+coyxBpW6Ce1tzo0l3/X3PZ5baW9a9OHmLQoa0K40=";
  };

  npmDepsHash = "sha256-BixrOUy1n+Xa4H88FP7lV08d2DfO0fhfGZBrg030MA0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
