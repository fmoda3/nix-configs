# Helper functions for neovim plugin configuration
{ pkgs }:
let
  replaceTemplateVars = template: vars:
    pkgs.lib.foldl'
      (acc: key: pkgs.lib.replaceStrings [ "@${key}@" ] [ (toString vars.${key}) ] acc)
      template
      (builtins.attrNames vars);
in
{
  # Create a plugin with lua configuration from a file
  # Usage: mkLuaPlugin catppuccin-nvim ./config/lua/catppuccin-config.lua
  mkLuaPlugin = plugin: configPath: {
    inherit plugin;
    type = "lua";
    config = builtins.readFile configPath;
  };

  # Create a plugin with lua configuration using template variable substitution
  # Usage: mkLuaPluginWithVars nvim-dap ./config/lua/dap-config.lua { python_debug_home = "${python-debug}"; }
  mkLuaPluginWithVars = plugin: configPath: vars: {
    inherit plugin;
    type = "lua";
    config = replaceTemplateVars (builtins.readFile configPath) vars;
  };
}
