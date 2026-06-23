{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-06-22";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "bbb7017d606e81565e6b1f1d864189c35a07e665";
    sha256 = "sha256-CDV+ZBt5UX9nWYeYm/ZUWXh4dLKwxxWUYonD8wvxC6s=";
  };

  prunePaths = [ ".github" ];
}
