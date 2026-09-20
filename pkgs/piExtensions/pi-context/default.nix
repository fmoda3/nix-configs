{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-09-20";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "34797213820e4f005160fa6148fe6a9e27400219";
    sha256 = "sha256-kqOTtftlj7Gi/ktiNgRwadKxnzdXpy1+3YWalTU/+pw=";
  };

  prunePaths = [ ".github" ];
}
