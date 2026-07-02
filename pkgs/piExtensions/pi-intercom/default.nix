{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-intercom";
  version = "2026-07-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-intercom";
    rev = "e234a4446e2b3f9c13a1ec3151ae2169315c810f";
    sha256 = "sha256-ksBWgJ+1hGIFRCtLcfod1ALMEFRkrC+pg0sF7Io56Ys=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-KNETPl4rV2IHiWChy1megGIjxPIc6NudQ0FOEH3J/Xs=";
}
