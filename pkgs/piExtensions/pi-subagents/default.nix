{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "fd6d45b31bcc2412d3aca9f4230be979e95b0a96";
    sha256 = "sha256-Q0bR1/c5ybZjUnM+rzLyBDdFOhH8eAnmDGNgeqMQL4I=";
  };

  npmDepsHash = "sha256-g04ignvpzDuq1BkVuwtnzK+uqsDOtVV5B+KfzO63z1o=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
