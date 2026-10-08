{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-10-08";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "1c0a43c3d73e9459bd8af8a5373c750fded3e97d";
    sha256 = "sha256-q7640Ov/C0t2JTu9hD3pgas+5U5YAd2ZvL6k+PERzns=";
  };

  prunePaths = [ ".github" ];
}
