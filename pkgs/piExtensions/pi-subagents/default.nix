{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-06-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e7edac1f40c0e58e5df382470be84cc675cb2af0";
    sha256 = "sha256-2UodbRnGL/oLzfGkD1y5lly8ONolpWxOILSD/yYWqu0=";
  };

  prunePaths = [ ".github" ];
}
