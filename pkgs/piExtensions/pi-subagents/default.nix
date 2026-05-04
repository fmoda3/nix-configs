{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3ee17de53d1a430b71519889741569c3991f99b7";
    sha256 = "sha256-534OtNSO5/YBM3/407wFMf8dwfImw1e38251mnEn63Y=";
  };

  prunePaths = [ ".github" ];
}
