{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "8063333661476ca48afbca826dc4aab8707c72d3";
    sha256 = "sha256-E6pk35MhwkEa1e+Egp5hhijpy5juIq2vEdayRoqdLDk=";
  };

  npmDepsHash = "sha256-NsNVeNmKlZoKbM5RZrVo1B9XCKTcWT3SSK7PPLCA7pg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
