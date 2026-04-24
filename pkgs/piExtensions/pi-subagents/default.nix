{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "5dc64307ca5e4f856909a0856a291a3665ae2b89";
    sha256 = "sha256-c+qwT/XFMicITrw39mDwrvL+XXaA/hbx6C1IVc14ha0=";
  };

  prunePaths = [ ".github" ];
}
