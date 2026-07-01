{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b58b275452da2c08b5d95a75109042e0cf437654";
    sha256 = "sha256-8/IRLB9eAjbaJ1+LoD0bZE6GZDIEud16mFo1H5LG7c0=";
  };

  prunePaths = [ ".github" ];
}
