{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "240b9d23590fd30a9013c41f3612085d5bb95865";
    sha256 = "sha256-CzqVKD6nDgIhgiHXRkT4QSO8QQA7YVRM6H5Wyv0S9eM=";
  };

  npmDepsHash = "sha256-4iHfVe/7y5xTT3tu8hhbrjOMr8OpkvgpCiDdWqMGVoQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
