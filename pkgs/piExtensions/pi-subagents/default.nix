{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "823bdae9ee65e5df76deec34b3c6ddaab74a9090";
    sha256 = "sha256-B5SZbMt3J3Oin2Vg9AVsxQFScditDbAb4DXz8MzF0TA=";
  };

  prunePaths = [ ".github" ];
}
