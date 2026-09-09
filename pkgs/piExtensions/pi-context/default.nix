{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-09-09";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "0235d4e762bb253fb1c4f781def0bc9eecbc4c45";
    sha256 = "sha256-xAuQUsshsdu8Ky9FLkOo9+PGHY1FVbI2Ek+ooSK4U6c=";
  };

  prunePaths = [ ".github" ];
}
