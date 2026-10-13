{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "8fcc3c787a6e7d9da0f21bafb604fe937084c21b";
    sha256 = "sha256-pMu6oQOs66XB5DbDw16uwooNofK+9cjRcDmyVmL+ojs=";
  };

  npmDepsHash = "sha256-ImygHIZc9Xj1QfWBoyJiWFJVm+oJMNn5aZO2q4Sj9hA=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
