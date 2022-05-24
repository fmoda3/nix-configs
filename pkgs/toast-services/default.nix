{ stdenv, fetchFromGitHub, pkgs, lib }:
stdenv.mkDerivation {
  pname = "toast-services";
  version = "1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/toast-services.git";
    rev = "2f002293fdab9d4b4473b7a80cfa93b488deef13";
    ref = "development";
  };

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/bin/lib
    cp deploy_g2_service.sh $out/bin/deploy_g2_service
    cp deploy_spa.sh $out/bin/deploy_spa
    cp destroy_g2_service.sh $out/bin/destroy_g2_service
    cp destroy_spa.sh $out/bin/destroy_spa
    cp lib/check_aws_env.bash $out/bin/lib/check_aws_env.bash
  '';

  postFixup = ''
    wrapProgram $out/bin/deploy_g2_service \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli ]}
    wrapProgram $out/bin/deploy_spa \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli ]}
    wrapProgram $out/bin/destroy_g2_service \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli ]}
    wrapProgram $out/bin/destroy_spa \
      --prefix PATH : ${lib.makeBinPath [ pkgs.awscli ]}
  '';
}