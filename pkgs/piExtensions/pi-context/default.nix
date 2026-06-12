{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-12";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "64fdbd6e444a12405b0ec3640003ffdb40b3c05b";
    sha256 = "sha256-VUD6naaid+9OkJ4pGinS0FkjkkBSGgUAjlC1VaVLnmA=";
  };

  prunePaths = [ ".github" ];
}
