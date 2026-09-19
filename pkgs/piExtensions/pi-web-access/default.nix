{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "6c5afa1d0d43eef8552284ad73f4bd9f0612a378";
    sha256 = "sha256-B8Ca1AH0OGM8nOKoWLI8Xukx0NNwU8FN84WzADa0v7c=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-4warQTTopcK5PSorV6C3W/6sTFP13kzC6ZFCoXYV350=";
}
