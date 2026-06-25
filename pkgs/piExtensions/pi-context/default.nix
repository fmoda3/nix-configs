{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-25";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "e5263cc46ae2e9b3e35c12193d97a01e4efeb9f5";
    sha256 = "sha256-WQOMvmCSawDgA0wmqfycFnxO7T06tQ/X61mTQkl/VmA=";
  };

  prunePaths = [ ".github" ];
}
