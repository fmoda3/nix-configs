{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "025a2ba29c4ed43aa5f35513e7f6d24cd75a5665";
    sha256 = "sha256-vhLSy+x0dwYFXwc2M40THzodtVra2Lx5cKclYfavnss=";
  };

  npmDepsHash = "sha256-QIEtFxFISqrQY4JoxtYig1jrgscX9yJvYB9ZxVVC2jo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
