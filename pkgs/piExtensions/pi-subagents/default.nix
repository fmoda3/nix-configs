{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a2db37889c8f06e36ed9cab958fa78e094b01f22";
    sha256 = "sha256-KPAXNW4kG06RsnIQRi6TbLvB4G9Rf0+dM+NN2rZkpdw=";
  };

  npmDepsHash = "sha256-qtYTJJ+BN715N9tzLOOPyAM5wymO0jfbVPi0HtRNkZo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
