{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-05-31";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "50b8bd0da3b390ef2eb145c02e58ac39d87c059d";
    sha256 = "sha256-PAKdIuqk0pnADfmBfZLcNkA5GYH9gaBBNwK1kj5FCHk=";
  };

  prunePaths = [ ".github" ];
}
