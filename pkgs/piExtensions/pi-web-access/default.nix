{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-07";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "9b3002a6c8f1b020eafcff8ec990c2bfdd32baea";
    sha256 = "sha256-u4Gw1NDqG9FJelJdGdohaN2BeN5Ymj76T5w4NXaGopk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QNn8JSPSTpbQ2FM4hyhYUsTPb9qW0Rr0D8DQ8/5r84w=";
}
