{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-06-29";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "2bba8543263c042c454d7f5eea557e1dd1381a0c";
    sha256 = "sha256-Zvqv0EF/TXXNP6NqFgD0VPrLNhUkWHGmFLjCbhzxkV8=";
  };

  prunePaths = [ ".github" ];
}
