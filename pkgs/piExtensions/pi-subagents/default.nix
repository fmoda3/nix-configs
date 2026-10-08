{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-08";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0c33ec7cb26ed1db270d72e746c3c975be880aeb";
    sha256 = "sha256-Th4hqqreb6WD4OkPRVBkq4+KQIF/kEoOi0cPIfjpyYA=";
  };

  npmDepsHash = "sha256-zPo0Z3IjaSEA74YptOUComiwvQxSMhPw7N6SwtGkveE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
