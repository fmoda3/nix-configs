{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-intercom";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-intercom";
    rev = "1ab886f6242a48956ebf3bb9578afbd79a57df9c";
    sha256 = "sha256-0TvWelxesSkaEEam/LutKAXvWJIszJ1Vr10lgSKkffY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-KNETPl4rV2IHiWChy1megGIjxPIc6NudQ0FOEH3J/Xs=";
}
