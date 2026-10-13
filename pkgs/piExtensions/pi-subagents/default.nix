{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a4c8ced69a8176cdf4179b127feddc8875e3418f";
    sha256 = "sha256-kTzwkgt+ZVRc5LoPCsryQcmMB9XJ5k5Tptrw3HV+9a8=";
  };

  npmDepsHash = "sha256-862hXsUJ7CSVSntkV1Iv4z5E2On8v5BJSbM9iIYe+GY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
