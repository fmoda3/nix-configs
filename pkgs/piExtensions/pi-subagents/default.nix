{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "de6957becc859561f74195c8c0a0a717831e6b95";
    sha256 = "sha256-vhrEkupVlDw42LZN1vd8L4QQkB5rM0yHpf8JPi7KCxI=";
  };

  npmDepsHash = "sha256-g04ignvpzDuq1BkVuwtnzK+uqsDOtVV5B+KfzO63z1o=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
