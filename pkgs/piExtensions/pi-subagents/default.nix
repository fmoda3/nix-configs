{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7d02a9f7d08dd4b282c064831d74f1664905091c";
    sha256 = "sha256-tGcglzZZe7pzPD5N+tLIaW9cWpqPDD7JiqtkR85KaIY=";
  };

  npmDepsHash = "sha256-8KDdekSgkECt6g2XtmMG4FsJA/e69fxqxJhLrkMgtME=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
