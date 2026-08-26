{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "17b04cf3669fecace0c97a22d8dc731f6a58c954";
    sha256 = "sha256-IGccvoMzqfKhyVqO13/Qbmm0b2O0Lkep8Ps4UPus96M=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-RtgWHi3WIuMFtJzuEbL+Acbes8TTjoL4b9VeHODWCGI=";
}
