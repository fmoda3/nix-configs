{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "8983754bb3ef6603cbbe46dcc2314ec8563ffc23";
    sha256 = "sha256-Z8PloXdWn0Am1fErHP6oVTk4QSyYRsBUmzhGBX68HKw=";
  };

  npmDepsHash = "sha256-4OQ8aB9FNBfh+k8GB9ajzQgUMdD4nBzAzqIrtQvoizU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
