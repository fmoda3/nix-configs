{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-08";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7bf05f9acc4a61d9ff50927fa8be7ad3f87d77b6";
    sha256 = "sha256-tLk/n0a5ZBa00CKe6DnfhiedPOBqOp99MT5Qg5sKTRc=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-42NRWAN2fxwr0q3pAyWTb5F6PJ0siu5Ux01/Tamn0Ew=";
}
