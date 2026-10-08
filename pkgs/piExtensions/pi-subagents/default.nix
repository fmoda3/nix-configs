{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-08";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "ad11b7ab1b09abd9a6ebdeff032f9c7279c606fc";
    sha256 = "sha256-kjKJL/yRPQ0chunEOh73s1oobhaz5JkvM0R386e0YU8=";
  };

  npmDepsHash = "sha256-zPo0Z3IjaSEA74YptOUComiwvQxSMhPw7N6SwtGkveE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
