{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-07";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9e8ce9e6af0074a531068b72505d9205f0b72774";
    sha256 = "sha256-4JUIamaBu1SkLpcZLP6ini82oHVHvQ4RJmMHQTEyMQg=";
  };

  npmDepsHash = "sha256-x9125j6dGqAqo4j/2r+QeoxHuyz59RakEBHlcEQnQCo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
