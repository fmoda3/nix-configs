{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3ce6185ac385e74f358ea9fb2dcd597e0351b8cc";
    sha256 = "sha256-yOp3UjZ2TnAGFzxd05CBJfOYlIwiPH5WfYW9TmMxIVY=";
  };

  npmDepsHash = "sha256-O+VByGju1YEhiHy1ic+I30YED5wVXSeIgabN4dJnzK0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
