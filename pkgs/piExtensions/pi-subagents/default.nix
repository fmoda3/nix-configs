{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "6a1ce6d8cb4baec13687a134bdfdc517a50763c1";
    sha256 = "sha256-J/X2NnT695BbBpapiIFfaoizNALrA91G4u/BXg5hn/c=";
  };

  npmDepsHash = "sha256-baLawPHlhq6kOfJGmpsX8t3Qy5AdKOqMhfN8mrqqFnQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
