{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "71843d1a89704423163f690a57da1d4ce83f4644";
    sha256 = "sha256-5GE743USI87RjWMeYF1DbarEcjpHAvKSwk/wAZJuIno=";
  };

  npmDepsHash = "sha256-Eq9sBYG0juwcV1nHtD8q1AzNg4sN4pCPiAodr7+bf1s=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
