{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-plan";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "burneikis";
    repo = "pi-plan";
    rev = "0eac3e305629a295a2d0fa17ff262854cf3cc7f5";
    hash = "sha256-vE/aDCe4DnAOY0+M53xXoV3plH9RxJs9naAGZD1Nu/M=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
