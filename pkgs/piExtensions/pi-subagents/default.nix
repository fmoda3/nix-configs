{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "085d860508256d26bcfdaa59a02fa6de60315c5c";
    sha256 = "sha256-s1KiNcQdzHCOIf8+qUqH+TDG2d5RT2SlkslbosWd/jU=";
  };

  npmDepsHash = "sha256-S6T0Y19PdpEwF3fbohGa7qPTS6tMZ52jCAv8luh436U=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
