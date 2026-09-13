{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "006ecf9ac15ff96b6b83b94f1e56de6eaa2f2f05";
    sha256 = "sha256-XYw8VoepcgYg9KuGYQfcDkHJRVaO754J2uWXgYgSl18=";
  };

  npmDepsHash = "sha256-Bto6gZcATd4R2ilK4fYlYzfiVaToLxR/6uCPSPqTuuI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
