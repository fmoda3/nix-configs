{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-10-15";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "b855c818bd395445824d3c5fd8e614d0cf98a963";
    sha256 = "sha256-XFlEwta/79+Sw3K0djKhBwGU97jbLgZdfWWP2vE4dBk=";
  };

  prunePaths = [ ".github" ];
}
