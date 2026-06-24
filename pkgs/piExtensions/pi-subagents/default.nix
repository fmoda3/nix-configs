{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-06-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e4f06282d0c95856b36b7ec2893f4fd294ebfefe";
    sha256 = "sha256-lvcf6VC6xfZ3j8oHpKoYPNQi8hKFLLhcQq5FxcjJaKk=";
  };

  prunePaths = [ ".github" ];
}
