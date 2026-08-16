{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "c77b28221d527f298d409d7e61ade661e548f50c";
    sha256 = "sha256-q/TZUkgeC/W/Ft7RMVIDc6m/Dsj2amicHhSeCbzk05E=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-CKGwaa86qO93+7An60EiHS6IPV9nBj2rPXHWid0vWX4=";
}
