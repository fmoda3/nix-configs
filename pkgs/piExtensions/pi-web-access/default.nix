{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "7ca5cdce4fdf33ddec3da4b1858215dcd0c0e382";
    sha256 = "sha256-KnNvhmQQXAVSUTTxcOAfTLLBMERafUbj5sXJoLtFAMs=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jzFFgbGXn9wCD6p8IRO1fNEv1sTIpWpvlYmESW33kMk=";
}
