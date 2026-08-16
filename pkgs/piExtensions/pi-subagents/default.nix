{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3f02afde1ca6e4c8ba0d0d028dcfffbdeeee3fa8";
    sha256 = "sha256-MMr88UeMkRoToz59N/U3feNwRsYgme5wGkZKumAsSco=";
  };

  npmDepsHash = "sha256-EvC8EVfkJXrzYdu5K4CSVNoFuZQ9nvUlzmRNhA0pf2A=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
