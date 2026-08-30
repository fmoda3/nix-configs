{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d7db00a2bb22fc8960dbee18ac25ea5aa15ea784";
    sha256 = "sha256-90MYVy7NzTCHgSUin95SKTWBjtpDuWhmvUK3/gUktu8=";
  };

  npmDepsHash = "sha256-YR7GAXzi4mTj1yG0ujpnqZnNaGYutLfpfP51/upVsGA=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
