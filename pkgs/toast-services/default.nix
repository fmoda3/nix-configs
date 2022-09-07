{ stdenv, fetchFromGitHub, pkgs, lib }:
stdenv.mkDerivation {
  pname = "toast-services";
  version = "1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/toast-services.git";
    rev = "d3fb9dc66ac404049d0afe54db7d49e7c4ec7e6b";
    ref = "development";
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
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
    cp lib/codebuild_libs.bash $out/bin/lib/codebuild_libs.bash
  '';

  postFixup = ''
    wrapProgram $out/bin/deploy_g2_service.sh \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli2 pkgs.jq ]}
    wrapProgram $out/bin/deploy_spa.sh \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli2 pkgs.jq ]}
    wrapProgram $out/bin/destroy_g2_service.sh \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli2 pkgs.jq ]}
    wrapProgram $out/bin/destroy_spa.sh \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli2 pkgs.jq ]}
  '';
}
