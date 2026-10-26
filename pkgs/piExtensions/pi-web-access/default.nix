{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "d95fb1eb4350b90bd4285cbc84958085d136aa43";
    sha256 = "sha256-P2dRLePZuM9ZTP1nnMtrbZbTb70uicxdR9fJby61Cpg=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jyIrcH9OmEPV9bn+BGLEccImRFRHd7ZxMSYGuISXg4Y=";
}
