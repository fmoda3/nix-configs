{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d75001352364e7ae0a48d8ebd1d4aa16bab2e5c7";
    sha256 = "sha256-pEt3r+Mm5P21lJXzGhP60Zuz3fKy6sJm+2w+VfFwqLY=";
  };

  npmDepsHash = "sha256-pZQPUGZnAfMRvexq7y26RamFFdzUhYo/T/vye8Fdwsc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
