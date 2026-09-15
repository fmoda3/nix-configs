{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "07bd09e0f93a19caee3c39e3cf4069c70ee8dbcd";
    sha256 = "sha256-RHhiKNxx2qqzr2irbP25S9ijOX5mqWnCzKDkserXmdQ=";
  };

  npmDepsHash = "sha256-nOPUvjttX8kkUdXSCSf+/OMx9APy5cfJTbt837oNY0Y=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
