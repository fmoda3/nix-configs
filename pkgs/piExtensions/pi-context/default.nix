{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-07-20";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "6527343b93a5b340e7d7cb44903e6e2dddc70bf5";
    sha256 = "sha256-xFXqPc+PRkPdX3nZ9V5zeCKagDWz5A7GVldSb33DJPA=";
  };

  prunePaths = [ ".github" ];
}
