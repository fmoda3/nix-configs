{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "726ecdbccf9dc2aa4dbf1aebee442ddba55025f1";
    sha256 = "sha256-sZKWHa6xi4l7UIvFcsWRiqYnbkHKz0CGDzQd0NI3pgw=";
  };

  prunePaths = [ ".github" ];
}
