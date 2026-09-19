{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-18";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f4918e80b531f1bf9f1d9e847b8f86c9016108f1";
    sha256 = "sha256-j6nEmECD1jDXBCgc65AJMa6QFtbRYq4TblGB7ghQ1Ms=";
  };

  npmDepsHash = "sha256-K9gDFwFEoXO8ekGOaSoq8OQ2CEVjX8kwOtY7PEdDWnw=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
