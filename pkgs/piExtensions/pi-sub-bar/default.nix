{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-sub-bar";
  version = "2026-03-25";

  src = fetchFromGitHub {
    owner = "marckrenn";
    repo = "pi-sub";
    rev = "65deb56853b924fbbcee1b77e09c71f5f08fc9a2";
    sha256 = "sha256-CoZlhizgn6V6YLiGvp+LI0xysSa10IYNh+a58D49qAY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r packages/sub-bar/* $out/

    # Vendor monorepo workspace deps needed at runtime.
    mkdir -p $out/node_modules/@marckrenn
    cp -r packages/sub-core $out/node_modules/@marckrenn/pi-sub-core
    cp -r packages/sub-shared $out/node_modules/@marckrenn/pi-sub-shared

    runHook postInstall
  '';
}
