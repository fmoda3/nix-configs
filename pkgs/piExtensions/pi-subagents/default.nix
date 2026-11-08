{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-07";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3ff4f75545edf2695d5ea82bf46a1ea9ef2008a8";
    sha256 = "sha256-DkelgRS5CRtyRYiILiVkrFXRY+H33/4LlbZVeFPhOwY=";
  };

  npmDepsHash = "sha256-aGw6EkTn6zIf29rx69B/6lEjHjxF6ZZCHbslXhy4ITg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
