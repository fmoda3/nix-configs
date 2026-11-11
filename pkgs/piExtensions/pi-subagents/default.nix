{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "c99503aed6d6b20d2397a1767f7d60730efe3963";
    sha256 = "sha256-DPeu8UEl0Oq+m3YirA4vXOaDmyyIVMkxBzMXEWrmVHo=";
  };

  npmDepsHash = "sha256-8/f62IizitxwVSAWOmWrPCoRBXjOj3JKtOHBUmpyyMg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
