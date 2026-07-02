{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "05019cda3917159efa5aa2ecd9d50834732a2b14";
    sha256 = "sha256-35WL7NjfHXKunyAzelEUzsf1PK7zMIKAau4kHP7+xB0=";
  };

  prunePaths = [ ".github" ];
}
