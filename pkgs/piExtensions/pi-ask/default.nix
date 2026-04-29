{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "0.6.1-unstable-2026-04-28";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "a29992123cb5dbe78bdb19b7382f2bd392c1f35d";
    sha256 = "sha256-u9kqxNW5KAYthoGruGCT+qTDZdJ6D1os/TliJCL1Z3E=";
  };

  prunePaths = [ ".github" ];
}
