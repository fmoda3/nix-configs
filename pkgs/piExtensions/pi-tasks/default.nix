{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-tasks";
  version = "2026-05-04";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "530d2dbd29c5d8ae6bebc3e184855507008fa5d0";
    sha256 = "sha256-/p6F6xaKIZSlgDWMCgBYGW4lROQN5wqr33lKJKmZ/LM=";
  };

  npmDepsHash = "sha256-F8JFX/wE7+Nn7j5oS1sDB2SicrNY+DJMRdN+fFLH5aU=";

  prunePaths = [
    ".github"
    "test"
    "media"
  ];
}
