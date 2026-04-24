{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-04-14";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "1d8bcf280f9c7ea0ee24249cacc9538eaee71a52";
    sha256 = "sha256-UZTbJrCvEMUsp75iqmogdE4XWzMPaZDPZiiX9qFFvXo=";
  };

  prunePaths = [ ".github" ];
}
