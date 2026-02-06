{ stdenv
, lib
, makeWrapper
, awscli2
, jq
}:
stdenv.mkDerivation {
  pname = "toast-services";
  version = "1.0";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/toast-services.git";
    rev = "ec5365aff322086af75abb1bcf7f18a675249d57";
    ref = "development";
    narHash = "sha256-pTBXLaFaP7lUOXUI61akiCcE6tRUlhyRsVz3LHN+z6Q=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/bin/lib
    cp deploy_g2_service.sh $out/bin/deploy_g2_service.sh
    cp destroy_g2_service.sh $out/bin/destroy_g2_service.sh
    cp lib/check_aws_env.bash $out/bin/lib/check_aws_env.bash
    cp lib/countdown.bash $out/bin/lib/countdown.bash
    cp lib/aws_libs.bash $out/bin/lib/aws_libs.bash
  '';

  postFixup = ''
    wrapProgram $out/bin/deploy_g2_service.sh \
      --prefix PATH : ${lib.makeBinPath [ awscli2 jq ]}
    wrapProgram $out/bin/destroy_g2_service.sh \
      --prefix PATH : ${lib.makeBinPath [ awscli2 jq ]}
  '';
}
