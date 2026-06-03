{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-notify";
  version = "2026-06-02";

  src = fetchFromGitHub {
    owner = "ferologics";
    repo = "pi-notify";
    rev = "a17c63ef1c3071d793aad7e9d327a3728f2ad88c";
    sha256 = "sha256-8oiWZhV/HpwAZyPL3Upi5EHDcqLwRdJd6SJBJk940tI=";
  };

  prunePaths = [ ".github" ];
}
