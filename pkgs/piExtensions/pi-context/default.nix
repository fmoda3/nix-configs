{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-08-04";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "7bcce4164ab6a504db9c4ed7b00c3732bffa9048";
    sha256 = "sha256-0Co51kvu8lw2gk5BCL22crLl556plUiqDR8kxMvuddU=";
  };

  prunePaths = [ ".github" ];
}
