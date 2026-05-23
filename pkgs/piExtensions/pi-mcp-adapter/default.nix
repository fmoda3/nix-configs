{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-05-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "c28c3608e4dd0e7eaf92cc4306ea9875bc60e077";
    sha256 = "sha256-DYQp/wgrEIqY7nVhJSB2oAVU+TZsWrI25BO0pxlmteg=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-bthHJ93+ny5LQnRYKoOxsEjIu5n6ibY0f83+T3NRGlo=";
}
