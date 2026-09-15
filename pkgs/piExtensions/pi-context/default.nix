{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-09-14";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "039919bb2580643bfd100375d05ad5b936b764a7";
    sha256 = "sha256-+yUsAIghApAINiH3/e0h5tGUGTKljlAVLG/dvxnJI60=";
  };

  prunePaths = [ ".github" ];
}
