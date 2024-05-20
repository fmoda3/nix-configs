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
    rev = "c3eabb716ec50da0ed8ebd80058674f2fac6131f";
    ref = "development";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/bin/lib
    cp deploy_g2_service.sh $out/bin/deploy_g2_service.sh
    cp deploy_spa.sh $out/bin/deploy_spa.sh
    cp destroy_g2_service.sh $out/bin/destroy_g2_service.sh
    cp destroy_spa.sh $out/bin/destroy_spa.sh
    cp lib/check_aws_env.bash $out/bin/lib/check_aws_env.bash
    cp lib/countdown.bash $out/bin/lib/countdown.bash
    cp lib/aws_libs.bash $out/bin/lib/aws_libs.bash
  '';

  postFixup = ''
    wrapProgram $out/bin/deploy_g2_service.sh \
      --prefix PATH : ${lib.makeBinPath [ awscli2 jq ]}
    wrapProgram $out/bin/deploy_spa.sh \
      --prefix PATH : ${lib.makeBinPath [ awscli2 jq ]}
    wrapProgram $out/bin/destroy_g2_service.sh \
      --prefix PATH : ${lib.makeBinPath [ awscli2 jq ]}
    wrapProgram $out/bin/destroy_spa.sh \
      --prefix PATH : ${lib.makeBinPath [ awscli2 jq ]}
  '';
}
