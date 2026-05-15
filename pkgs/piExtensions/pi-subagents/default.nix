{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e99bf5b84dc543012e2e4dee2478d6f914a37b27";
    sha256 = "sha256-giJ9SUjWz7qAInYZBijPOQSNjdEOtysLCf11rht2Gf8=";
  };

  prunePaths = [ ".github" ];
}
