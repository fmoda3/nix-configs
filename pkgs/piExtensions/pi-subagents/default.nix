{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d9c5ca29d881ee173681cafb66af1cc774285276";
    sha256 = "sha256-mz4rZkHHjWRhKZE2YaVqF4TTYQ+kIel5S0lQohMfoyg=";
  };

  npmDepsHash = "sha256-jpFrTf4WLn2XKL2/J+bPyQ0d4bKnGoxuFs+ez/MWkAE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
