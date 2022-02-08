{ config, lib, pkgs, ... }: 
let
  toastpackages = with pkgs; {
    oktoast = callPackage ../pkgs/oktoast { };
  };
in
  {
    programs.git = {
      userEmail = "frank@toasttab.com";
      userName = "Frank Moda";
    };

    home = {
      packages = [
        pkgs.saml2aws # oktoast dep
        pkgs.gnused # oktoast dep
        # gnused installs "sed", but oktoast needs "gsed"
        (pkgs.writeShellScriptBin "gsed" "exec -a $0 ${pkgs.gnused}/bin/sed \"$@\"")
        pkgs.awscli # oktoast dep
        toastpackages.oktoast
      ];
    };
  }
