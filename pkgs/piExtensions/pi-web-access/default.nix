{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "049587ea3f6dc4d1b0519f17e854ed7e5f57e4b2";
    sha256 = "sha256-culvDJyexdP3eS6w3nfSBbWQ7atWD1iLH0PS+CpUA8k=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QHwlmQnHYKzj6XdoTLIunPs1gTjpyUfNF6p6QS6cfms=";
}
