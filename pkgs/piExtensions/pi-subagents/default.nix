{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "5bac515cd79f39f6c74994f735d5dc6df71f3ce3";
    sha256 = "sha256-Ly1hxvkyYhGyTjdR+wcWami2PDQXt5UUD98+ZRkhwzQ=";
  };

  npmDepsHash = "sha256-e06UDCU9uhzpjlXi26rqrPM1cHMiVmqHzY4qgbN9lPo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
