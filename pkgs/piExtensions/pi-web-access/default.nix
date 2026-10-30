{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "fc63125608faef80c446687c79edd2626f511019";
    sha256 = "sha256-bXCnQwfz0svaWj/d3ES0AyA8J6ZivKYYqfa3f9nhyTQ=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-CI82BmyV+EKJFxhQS2DZJkQQvsVPvdd5ru162pDjPJs=";
}
