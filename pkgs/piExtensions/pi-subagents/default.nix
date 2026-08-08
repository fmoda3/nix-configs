{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-08";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e782287a642b2eb66e722331c6e17059559057e3";
    sha256 = "sha256-3Brg55ouhKuAkStOPkeEGxHFV3sjqBIQDiMTYDeaNPk=";
  };

  npmDepsHash = "sha256-x9125j6dGqAqo4j/2r+QeoxHuyz59RakEBHlcEQnQCo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
