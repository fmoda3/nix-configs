{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7e8f1cf0b4473b830768eb5d313d95544a139c28";
    sha256 = "sha256-dy3hQJ/BKBcT7azRHQsoQVY/85O03BndInB2T1Hkm2I=";
  };

  npmDepsHash = "sha256-8KDdekSgkECt6g2XtmMG4FsJA/e69fxqxJhLrkMgtME=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
