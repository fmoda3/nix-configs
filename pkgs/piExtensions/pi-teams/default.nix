{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-teams";
  version = "2026-04-03";

  src = fetchFromGitHub {
    owner = "burggraf";
    repo = "pi-teams";
    rev = "d01336d0b3f948988ffda76a7a06021ea82c212a";
    sha256 = "sha256-Pi9WFgeEn6+vgycfekSVW9ozmjvQ70S4alzL/mKRWwk=";
  };

  prunePaths = [ ".github" ];
}
