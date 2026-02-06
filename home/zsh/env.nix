# Environment variables for zsh
# Separated into common (all machines) and work-specific
{ config, pkgs, lib }:
let
  # Catppuccin Frappe theme colors
  themeColors = {
    GREP_COLOR = "38;2;202;158;230";
    GREP_COLORS = "ms=38;2;202;158;230:mc=38;2;166;209;137:fn=38;2;153;209;219:ln=38;2;229;200;144:bn=38;2;186;187;241:se=38;2;129;200;190";
  };

  # Common variables (available on all machines)
  commonVariables = {
    PAGER = "bat --style=plain --paging=always";
    EDITOR = "vim";
    VISUAL = "vim";
  } // themeColors;

  # Work variables (when isWork = true)
  workVariables = lib.optionalAttrs config.my-home.isWork {
    TOAST_GIT = "${config.home.homeDirectory}/Development";
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    FLAGGY_TOKEN = ''$(${pkgs.coreutils}/bin/cat ${config.age.secrets."flaggy_token".path})'';
    BRAID_PULSAR_MDC_PROPAGATION_KEYS = "Toast-Braid-Route,Toast-Braid-Services";
    GH_HOST = "github.toasttab.com";
    OKTOAST_PROVIDER = "Browser";
  };
in
commonVariables // workVariables
