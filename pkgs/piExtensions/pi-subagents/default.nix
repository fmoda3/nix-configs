{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-18";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "c20f49ef951ca523e09e24d1da8eb1598a1c7cec";
    sha256 = "sha256-HPf2/DL+69E1M8hjsBJ/RUs6Ie9lg85+3UqpgqeQfxI=";
  };

  npmDepsHash = "sha256-kJqaHv5+vHj8F1QpK9ocsoXetdCoTtqC8aEq92yvUKk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
