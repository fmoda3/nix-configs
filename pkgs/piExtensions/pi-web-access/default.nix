{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-11";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7e488620f32de239992d45eac83235d03c9c6bbd";
    sha256 = "sha256-LEkOQX4qsQwDtodP7qWCCrTptG1E6O6sJGVsL0+Eg8g=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ouqaLRfRlLZRzW4FFiVF4wmMj5xe5qTTcceceaNKenM=";
}
