{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-14";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "127c3139774b0c217848fd2a3def18e81802a504";
    sha256 = "sha256-pJ8vVrSq0saIggONH7CsW5i2hNcNiqtkXspa3LH+EI4=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ouqaLRfRlLZRzW4FFiVF4wmMj5xe5qTTcceceaNKenM=";
}
