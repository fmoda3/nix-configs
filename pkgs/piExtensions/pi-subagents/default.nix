{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-09";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "68cccb5fbf46003d78abc4e2ecd2f9e4d6b825d7";
    sha256 = "sha256-LvErM0oV1y0/qQHPuYtTKKGsZGmM3qAvxPepRCATojw=";
  };

  npmDepsHash = "sha256-zPo0Z3IjaSEA74YptOUComiwvQxSMhPw7N6SwtGkveE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
