{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-06-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "efa7120047eaf76a32620eed0ec7d038b6cfa44e";
    sha256 = "sha256-AnS2qddwILanANlXsHo8X7lHEula9XQHs+13UgYPCMI=";
  };

  prunePaths = [ ".github" ];
}
