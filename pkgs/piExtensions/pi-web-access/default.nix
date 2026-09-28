{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "9a734ed195da2f4cccc2fb5e7128f6774a380f47";
    sha256 = "sha256-91kQHNZzeizb+gS/5WthzA+ee9txH7J6U6m7kQRphXA=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QHwlmQnHYKzj6XdoTLIunPs1gTjpyUfNF6p6QS6cfms=";
}
