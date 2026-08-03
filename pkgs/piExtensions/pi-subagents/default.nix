{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "eb13fb35151e916173d46447685cab4275b302ae";
    sha256 = "sha256-p+Oq3XDLRp/mFrApr5y7UhJK1OCLT8zUNtpZaAHExDk=";
  };

  npmDepsHash = "sha256-8KDdekSgkECt6g2XtmMG4FsJA/e69fxqxJhLrkMgtME=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
