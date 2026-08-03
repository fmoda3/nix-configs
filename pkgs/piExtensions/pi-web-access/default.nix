{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "0fa01ea1cb351ddf30fda9e032ae1e8f0fad92fb";
    sha256 = "sha256-XWOocJfW7oUAUcXZ6EtdUTaE2SQLMR2MJR4JfuAZXLY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-42NRWAN2fxwr0q3pAyWTb5F6PJ0siu5Ux01/Tamn0Ew=";
}
