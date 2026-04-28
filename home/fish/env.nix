# Environment variables for fish
# Separated into common (all machines) and work-specific
{ config, pkgs, lib, ... }:
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

  # Personal variables (when isWork = false)
  personalVariables = { };
  personalCommandVariables = lib.optionalAttrs (!config.my-home.isWork) {
    OPENROUTER_API_KEY = "${pkgs.coreutils}/bin/cat ${config.age.secrets."openrouter_key".path}";
  };

  # Work variables (when isWork = true)
  workVariables = lib.optionalAttrs config.my-home.isWork {
    TOAST_GIT = "${config.home.homeDirectory}/Development";
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    BRAID_PULSAR_MDC_PROPAGATION_KEYS = "Toast-Braid-Route,Toast-Braid-Services";
    GH_HOST = "github.toasttab.com";
    OKTOAST_PROVIDER = "Browser";
  };
  workCommandVariables = lib.optionalAttrs config.my-home.isWork {
    FLAGGY_TOKEN = "${pkgs.coreutils}/bin/cat ${config.age.secrets."flaggy_token".path}";
  };

  commandVariableLine = name: command:
    "set -gx ${name} (${pkgs.bash}/bin/bash -c ${lib.escapeShellArg command})";
in
{
  programs.fish.shellInit = lib.concatStringsSep "\n" (
    (lib.mapAttrsToList (name: value: "set -gx ${name} ${lib.escapeShellArg value}")
      (commonVariables // personalVariables // workVariables))
    ++ (lib.mapAttrsToList commandVariableLine
      (personalCommandVariables // workCommandVariables))
  );
}
