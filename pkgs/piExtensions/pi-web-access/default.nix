{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-07-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "58ce1566b5959552cf9e8b9f227b158b199a4975";
    sha256 = "sha256-M3LvILyZU7q+6ZG4pch35aXJLY3xzYTzvsC4E3DZdio=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QHUcP518ATpoMGr+7aLfOe4oOtH0GpCu/nQYA42gqKU=";
}
