{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3ac0ef57115584b77bab1882033056af720d79c2";
    sha256 = "sha256-t4yauldCgDlFtNb8ssh8lakp2RpGdBju207qrUWy6Jo=";
  };

  prunePaths = [ ".github" ];
}
