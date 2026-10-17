{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-17";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "1e272e942bd8d2e6446494ce5de7a21a3f58ab55";
    sha256 = "sha256-7YtlmyqqCzSY3tAoMyc9CmjsY9UXSc3urXdPbQyGegA=";
  };

  npmDepsHash = "sha256-XqdBigQ1lrHr9qmBi36lsAm8rtsY0jPBETrAISxJzyE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
