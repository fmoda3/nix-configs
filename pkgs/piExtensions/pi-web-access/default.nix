{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-18";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "3b875f574840eebae39e5fede0d99a5f7c71f482";
    sha256 = "sha256-1E6ogt3gL+UhuLaTiLYlcDgjKar9AP3izuDEk1erXlI=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-db4DqtCAnoWYte/KEvvujr5wXx1rVDu/tdyGq6v/zk8=";
}
