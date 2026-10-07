{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "5da808168c097ea0d56616644773efe0f6f87938";
    sha256 = "sha256-YA4sxZOSduIOA2YbMNx1Vw1mdh32iK6AyKySbcOjpD8=";
  };

  npmDepsHash = "sha256-zPo0Z3IjaSEA74YptOUComiwvQxSMhPw7N6SwtGkveE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
