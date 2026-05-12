{ pkgs, ... }:
let
  settings = {
    onboarding = false;
    theme = {
      name = "catppuccin";
    };
  };

  toml = pkgs.formats.toml { };
in
{
  xdg.configFile."herdr/config.toml".source = toml.generate "herdr-config.toml" settings;
}
