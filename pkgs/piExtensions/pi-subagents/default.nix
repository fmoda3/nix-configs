{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "2e9c51bada2da6a9ba73b6973e1545a9afa0d057";
    sha256 = "sha256-PDdRd2lSVVcUOmv6Q6dHrwnVjHDnQYR9hjdRzif0D8U=";
  };

  npmDepsHash = "sha256-iphThPMza97zUMs+d2hWuPYrfYUBX+Dwhp8StgHcx/g=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
