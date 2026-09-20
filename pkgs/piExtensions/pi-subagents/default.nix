{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b72714de95e612406b3461e63dfc182856333a7e";
    sha256 = "sha256-Qyc0lWSo0WDNQZZvPWj/g4rvUbFa5ci96Rt2onUK+FY=";
  };

  npmDepsHash = "sha256-cCuW37hsiDVdOrR7HUUBueviNF1QZRPx+vvnm8CahYw=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
