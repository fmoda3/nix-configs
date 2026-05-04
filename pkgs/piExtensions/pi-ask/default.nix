{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-05-03";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "8c02565a5fcec09b0b35e65b5412a8a5489f8a75";
    sha256 = "sha256-oVWr6IOTQYn6J+SG/7qH/VvRyvo7wBZvEwizeDJ9Xrs=";
  };

  prunePaths = [ ".github" ];
}
