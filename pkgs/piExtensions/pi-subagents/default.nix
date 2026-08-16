{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "19a4e6073550edda2ed35163b087fd01b55b8a29";
    sha256 = "sha256-P3wNkQ8LhftmSWKZHxG5pk1xhHHt6ZJZJ/DV4RsoI9A=";
  };

  npmDepsHash = "sha256-EvC8EVfkJXrzYdu5K4CSVNoFuZQ9nvUlzmRNhA0pf2A=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
