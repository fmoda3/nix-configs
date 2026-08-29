{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "2155514dfc4c4d0f0223cef7f194ca6a95b5e90c";
    sha256 = "sha256-+e4K6Jw1pM9kD7taG/OQtfiT/QR++Xu0oSxlvo0D5c8=";
  };

  npmDepsHash = "sha256-Rdm4REYhKfFZkwpTLpEpsiqF03OTLfQp+z49q+JSqpE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
