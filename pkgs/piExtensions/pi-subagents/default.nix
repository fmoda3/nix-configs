{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "72c0d39c0572b4060e1a90cc9897300ef174c349";
    sha256 = "sha256-Vfisf8t/FBZY8qxVakgU6Dk9R/XN7qhKjCgOIqZK5ao=";
  };

  npmDepsHash = "sha256-4iHfVe/7y5xTT3tu8hhbrjOMr8OpkvgpCiDdWqMGVoQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
