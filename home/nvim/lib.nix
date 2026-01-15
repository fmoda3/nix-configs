# Helper functions for neovim plugin configuration
{ pkgs }:
{
  # Create a plugin with lua configuration from a file
  # Usage: mkLuaPlugin catppuccin-nvim ./config/lua/catppuccin-config.lua
  mkLuaPlugin = plugin: configPath: {
    inherit plugin;
    type = "lua";
    config = builtins.readFile configPath;
  };

  # Create a plugin with lua configuration using replaceVars for substitution
  # Usage: mkLuaPluginWithVars nvim-dap ./config/lua/dap-config.lua { python_debug_home = "${python-debug}"; }
  mkLuaPluginWithVars = plugin: configPath: vars: {
    inherit plugin;
    type = "lua";
    config = builtins.readFile (pkgs.replaceVars configPath vars);
  };
}
