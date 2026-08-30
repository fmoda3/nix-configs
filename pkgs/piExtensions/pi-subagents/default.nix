{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d8ff22d9290cc7ad49c1ee68e83779d8a730a34a";
    sha256 = "sha256-IeQPEleDSkHMhtFWHTqT8VDusMxC3X6bwdJDvwALhEA=";
  };

  npmDepsHash = "sha256-Rdm4REYhKfFZkwpTLpEpsiqF03OTLfQp+z49q+JSqpE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
