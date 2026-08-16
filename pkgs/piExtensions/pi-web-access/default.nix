{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "81e18785fdf6e14f9dee28d8a805c74eca29b991";
    sha256 = "sha256-zMuL0DFBfDS53lwh6lU1Ue6gImw4uqDlZZ5fncKJbjk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-CKGwaa86qO93+7An60EiHS6IPV9nBj2rPXHWid0vWX4=";
}
