{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "6acfc595c073312ca421a65f33796b6a3582ec41";
    sha256 = "sha256-V9hfedwdi1NtlW6abUzmL5q+i5hmaYto+kgEWuEhxW8=";
  };

  prunePaths = [ ".github" ];
}
