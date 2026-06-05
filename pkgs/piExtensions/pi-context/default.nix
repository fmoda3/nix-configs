{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-05";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "b6ef5640b47c33b513aa7d06d735e1ee757cadf1";
    sha256 = "sha256-ax6/QmcnYwQJUgs862tx11Gj0mvgo2CkTi60e6tDjHs=";
  };

  prunePaths = [ ".github" ];
}
