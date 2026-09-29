{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7ff8070cc317146c42878656d59e76a284a4b625";
    sha256 = "sha256-qAtWGP2BgFtz9CAcOmjxPAZT9hJYbwUUpwws+QRrP1Q=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QHwlmQnHYKzj6XdoTLIunPs1gTjpyUfNF6p6QS6cfms=";
}
