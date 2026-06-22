{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-06-21";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "e233514f34d9b73b4d6084534d7a6b0376a7641b";
    sha256 = "sha256-SveRhcIfwXnOGfFMiaooHbrV9P+Z3XKoE1R5zKrdNU8=";
  };

  prunePaths = [ ".github" ];
}
