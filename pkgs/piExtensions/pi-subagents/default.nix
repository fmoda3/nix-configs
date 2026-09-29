{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f34efb13140951fd537ad35f571eb5f39afb4dc3";
    sha256 = "sha256-OAsdTjxVcWOkqzJfTZZYCdHfTYUuJdGx+I4OkC8uQ4Q=";
  };

  npmDepsHash = "sha256-+J6qyk9JRD/C90zXq6CCBmgaPdxiGEs/C4wyPP0bKG0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
