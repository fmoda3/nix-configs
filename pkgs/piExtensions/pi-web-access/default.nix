{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-06-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7bdc30a65cf77273eb9c0034647b373bda4060d7";
    sha256 = "sha256-TPtkurLY8Z9qxa597e0C5yWlNvgz4ywv2GdQstTB33A=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-qYhBVN0sVNcvo7I0P7Yzm6carcTsu/IQiQBekz9U4YE=";
}
