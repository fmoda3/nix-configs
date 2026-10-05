{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "6826b0545216077195ae8ffe468a6434715814b7";
    sha256 = "sha256-1VPyNY5dFbFMPs9OJd/fwhPgqFcPLZxwd15sAtNsn/Y=";
  };

  npmDepsHash = "sha256-8HIc7Ep8OOKUM3hsGtg3t4aunupvZ10h797jizvz1p0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
