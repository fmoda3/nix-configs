{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "92b2c824939e775d7cdbf5cc22cb2ea3e556a642";
    sha256 = "sha256-2enASsCphN7R0/y9Qs1b1bJS/MrnsMMcXDEhEq8m/Co=";
  };

  npmDepsHash = "sha256-vI8xGVxur4flv1CzfTLrWLD1+xrVNoRfIv9LD7jMzNs=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
