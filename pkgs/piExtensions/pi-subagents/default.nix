{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9a8d3c529a502fe0ba5585323989b5e152a6f513";
    sha256 = "sha256-nh/8FgBsksuMEXQ+E2EnOZu1UaNzGLzjviyC3xhz8RU=";
  };

  npmDepsHash = "sha256-TbQEk7BEsVJx6pu1de/cMKehu0Ga89IJJBu1FARELfc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
