{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "711cc41313202e277a248b1cc45942b6dc8927f7";
    sha256 = "sha256-ngIYSP0DykKYYnxklyLiabEw4ldTfqng/AvuujinUoI=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jzFFgbGXn9wCD6p8IRO1fNEv1sTIpWpvlYmESW33kMk=";
}
