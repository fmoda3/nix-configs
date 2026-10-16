{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "b3f676d8448ede197d8cd22589beeb9e44f1cf44";
    sha256 = "sha256-7muKR7cMZlwpBVLXj4cTKImmPwCkO+GcPyLChs7Csto=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-9dJqmTQc80Ny+dAzyH2OkCfKTnlUZ54w28E4lwVOvNE=";
}
