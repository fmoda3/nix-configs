{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "635112deea068528d89694e58ca068ddc1fe4b2d";
    sha256 = "sha256-yBWgnZYw4OjSxKOmiQOltdM/jSbnHa/tdOBwUgNDkXU=";
  };

  prunePaths = [ ".github" ];
}
