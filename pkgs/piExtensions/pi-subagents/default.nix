{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f8ada81303db6ee76ed22fee5605dc8a8d62a83a";
    sha256 = "sha256-8o04729reu4qRXtGeLF+v/kC5aXN5RJ5blMRlMsAur4=";
  };

  npmDepsHash = "sha256-862hXsUJ7CSVSntkV1Iv4z5E2On8v5BJSbM9iIYe+GY=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
