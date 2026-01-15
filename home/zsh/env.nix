# Environment variables for zsh
# Separated into common (all machines) and work-specific
{ config, pkgs, lib }:
with lib;
let
  # Catppuccin Frappe theme colors
  themeColors = {
    GREP_COLOR = "38;2;202;158;230";
    GREP_COLORS = "ms=38;2;202;158;230:mc=38;2;166;209;137:fn=38;2;153;209;219:ln=38;2;229;200;144:bn=38;2;186;187;241:se=38;2;129;200;190";
    LS_COLORS = "di=38;2;140;170;238:ln=38;2;166;209;137:ex=38;2;231;130;132:*.tar=38;2;202;158;230:*.zip=38;2;202;158;230:*.gz=38;2;202;158;230:*.bz2=38;2;202;158;230:*.7z=38;2;202;158;230:*.rar=38;2;202;158;230:*.jpg=38;2;229;200;144:*.jpeg=38;2;229;200;144:*.png=38;2;229;200;144:*.gif=38;2;229;200;144:*.bmp=38;2;229;200;144:*.svg=38;2;229;200;144:*.mp4=38;2;239;159;118:*.mkv=38;2;239;159;118:*.avi=38;2;239;159;118:*.mov=38;2;239;159;118:*.webm=38;2;239;159;118:*.mp3=38;2;166;209;137:*.flac=38;2;166;209;137:*.wav=38;2;166;209;137:*.ogg=38;2;166;209;137:*.pdf=38;2;231;130;132:*.doc=38;2;231;130;132:*.txt=38;2;198;208;245";
  };

  # Common variables (available on all machines)
  commonVariables = {
    PAGER = "bat --style=plain --paging=always";
    EDITOR = "vim";
    VISUAL = "vim";
  } // themeColors;

  # Work variables (when isWork = true)
  workVariables = optionalAttrs config.my-home.isWork {
    TOAST_GIT = "/Users/frank/Development";
    DOCKER_HOST = "unix:///Users/frank/.colima/default/docker.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    FLAGGY_TOKEN = ''$(${pkgs.coreutils}/bin/cat ${config.age.secrets."flaggy_token".path})'';
    BRAID_PULSAR_MDC_PROPAGATION_KEYS = "Toast-Braid-Route,Toast-Braid-Services";
    GH_HOST = "github.toasttab.com";
    OKTOAST_PROVIDER = "Browser";
  };
in
commonVariables // workVariables
