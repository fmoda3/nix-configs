{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "479e282e01490d498abed8bdf33b98cb5625f796";
    sha256 = "sha256-mQrfh56yvBW1fPX8JmIkssh3l2QLaBUQejg6ypcZyWY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jzFFgbGXn9wCD6p8IRO1fNEv1sTIpWpvlYmESW33kMk=";
}
