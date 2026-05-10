{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-05-10";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "d5b69f05e376152b0692be15507fcae9aa286969";
    sha256 = "sha256-9czNAl/7M7t8lGJcLrWL9m0/xqHjGya07hiNojA78as=";
  };

  prunePaths = [ ".github" ];
}
