{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9d72792ad3a4eb5edec891593af2c62b6a0ec2bd";
    sha256 = "sha256-dtCaCfbPr8T346HkNT63GsOBgjaVREVjpk2RKpPa3pg=";
  };

  npmDepsHash = "sha256-QGZf89MAu0Miyl/Xf7e6Xi5PqVmrsLFg94K60GALBSE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
