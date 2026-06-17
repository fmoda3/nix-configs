{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-17";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "86934f89936a812a6d319cd18b9b2a0c33d04198";
    sha256 = "sha256-YAILi9DrGVHuyVObGIez80gGJQGyrdYosWILs9R5T8I=";
  };

  prunePaths = [ ".github" ];
}
