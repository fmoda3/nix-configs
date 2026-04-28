{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-tasks";
  version = "2026-04-28";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "30c3452fd1292860482f1afc7908edb76a46f1ed";
    sha256 = "sha256-NQxXpA0Phze+cXGvyu5KLhNX9/hkGnnhQyoPtYGArSk=";
  };

  npmDepsHash = "sha256-BU8Xni+K/+nk2FmK8FkWCg4iGG5PWR9FFLkckfd356c=";

  prunePaths = [
    ".github"
    "test"
    "media"
  ];
}
