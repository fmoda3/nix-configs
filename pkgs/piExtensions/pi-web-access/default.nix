{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-07-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "a1135b8ca054ba5f16ec4410d06928ce10da13c0";
    sha256 = "sha256-hvzXsooZ1N4a4swcY7od/z+yYyfWXxiFShhE5gTNWSc=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ojzAmEeFsWLIsFO0DshtTHzdfIvSfXqbSXooqJ73yhI=";
}
