{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "53945b578d8d4f2365dcb2f11c817f874fc91977";
    sha256 = "sha256-pmJ8AWw/QshcvLxS57kd261wccLpb/IEXDrKdZ48kck=";
  };

  npmDepsHash = "sha256-vI8xGVxur4flv1CzfTLrWLD1+xrVNoRfIv9LD7jMzNs=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
