{ stdenv
, lib
, makeWrapper
, writeShellScriptBin
, saml2aws
, gnused
, awscli
}:
stdenv.mkDerivation {
  pname = "oktoast";
  version = "1.0";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/oktoast-setup.git";
    rev = "572d166d4d56732ed22ec2d11aee09e13e4ecb70";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  postPatch = ''
    # Replace hardcoded aws_session_duration = 3600 with variable substitution for bedrock
    # This works within heredoc blocks by using variable substitution
    sed -i 's/aws_session_duration = 3600/aws_session_duration = $AWS_SESSION_DURATION/' oktoast

    # Add logic after ENVIRONMENT=$1 to set the session duration based on environment
    sed -i '/ENVIRONMENT=\$1/a\
    \
    # Set AWS session duration based on environment\
    if [[ "$ENVIRONMENT" == "bedrock" ]]; then\
      AWS_SESSION_DURATION=43200\
    else\
      AWS_SESSION_DURATION=3600\
    fi' oktoast
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp oktoast $out/bin
  '';

  postFixup = ''
    wrapProgram $out/bin/oktoast \
      --prefix PATH : ${lib.makeBinPath [
        saml2aws
        # gnused installs "sed", but oktoast needs "gsed"
        (writeShellScriptBin "gsed" "exec -a $0 ${gnused}/bin/sed \"$@\"")
        awscli
      ]}
  '';
}
