{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "227866b53234364fc52ac293d78a1d8e854d2730";
    sha256 = "sha256-0ZEFeb3r36DMkfUrIx2oiK6KK7W1q6LvQb+y9w5EYFI=";
  };

  npmDepsHash = "sha256-Zet4i/F3aD4MVvNPmGtSazFtC4pNZ5duRqNf8SYXxb0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
