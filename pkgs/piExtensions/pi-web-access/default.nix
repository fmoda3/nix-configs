{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "5741f303a4f5b89fed18e02ec3fed038844e0e98";
    sha256 = "sha256-V8KmLgfKpasnJNBCmjhe6VLeaUCW2RaUYqD24RR0XdU=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jzFFgbGXn9wCD6p8IRO1fNEv1sTIpWpvlYmESW33kMk=";
}
