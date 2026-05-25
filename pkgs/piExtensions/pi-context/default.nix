{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-05-25";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "eea5c66562f01f9fdb31100ff11cce1e8a00fe59";
    sha256 = "sha256-ZHQX6Kcq5F5Hv+VQPYE/Kgz/PLOtqwgIBPN+U00mRQU=";
  };

  prunePaths = [ ".github" ];
}
