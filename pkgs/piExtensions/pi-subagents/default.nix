{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9b003e4392ad6821b6b0c22f5101314e375a7ebf";
    sha256 = "sha256-PXad+30KyPUwDidy0M2X/iHGWhm5fFR7alIQjQkKJJw=";
  };

  prunePaths = [ ".github" ];
}
