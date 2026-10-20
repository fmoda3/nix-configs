{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7fcb1531fbc4b86cef12e8851f66b42e6385e0ce";
    sha256 = "sha256-RRK2lyffu+nq+QP4yZzSEoHNMZ847Knpdywi7yGbylE=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-dk4jXQCPt+lG865GTbhKGVOOMDPkF3+6BOLlJ+KC8hA=";
}
