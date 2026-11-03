{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-notify";
  version = "2026-10-22";

  src = fetchFromGitHub {
    owner = "ferologics";
    repo = "pi-notify";
    rev = "930b5b73d77c0545eb8bd4e56780cbbda3e7f305";
    sha256 = "sha256-7hgWi6CiqJ68R2Z3zivlIEdX12ZmY+zedMvXr0u+UYs=";
  };

  prunePaths = [ ".github" ];
}
