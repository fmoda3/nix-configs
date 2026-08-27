{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "6559ab29ddb881d099d16b05612e7589afc678f3";
    sha256 = "sha256-3r8steyZxwmifbJKTdz+RPnj/TttT6+1uQW2d3NGrb8=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-RtgWHi3WIuMFtJzuEbL+Acbes8TTjoL4b9VeHODWCGI=";
}
