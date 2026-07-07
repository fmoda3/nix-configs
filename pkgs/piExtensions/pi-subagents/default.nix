{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-07-07";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3ccb5645000709fc7856b1a9e3048009f19afaaf";
    sha256 = "sha256-6Q7NXRrQP2TtTeB72ZNdpgajCFLRe9LtyuBWzjDZ8dI=";
  };

  prunePaths = [ ".github" ];
}
