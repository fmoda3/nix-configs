{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-plan";
  version = "2026-08-22";

  src = fetchFromGitHub {
    owner = "burneikis";
    repo = "pi-plan";
    rev = "bf6365411fdd8813c609754329863e79a22655dd";
    hash = "sha256-O6UbQvOv5X3meTUdlRSBAuGtqbpjXyM9i9jYRSY6Dh0=";
  };
}
