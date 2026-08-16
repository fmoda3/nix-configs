{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "49482b7e5d0d57be8af1db81f490f6e860792cfb";
    sha256 = "sha256-lHAJMmtlnZyHU+QYUOyAiwnksm+DBu1FPqXhhr9qPLo=";
  };

  prunePaths = [ ".github" ];
}
