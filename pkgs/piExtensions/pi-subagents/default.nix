{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "4dc6576923ddef63d459a197ecdcb48b6b617a42";
    sha256 = "sha256-5DgZtVsGfVJhaexC2wrsM4CL/lTxJp4Y4fFbilYYdpk=";
  };

  npmDepsHash = "sha256-pxhGx0W53nVdj3FLeC3PGnQIksYTlDVZMOUxBOnrSzg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
