final: prev:
{
  # Adding packages here, makes them accessible from "pkgs"
  homebridge = prev.callPackage ./homebridge { };
  homebridge-config-ui-x = prev.callPackage ./homebridge-config-ui-x { };
  nix-cleanup = prev.callPackage ./nix-cleanup { };
  oktoast = prev.callPackage ./oktoast { };
  # python3Packages = prev.python3Packages // {
  #   toast-tools = prev.callPackage ./toast-tools { };
  # };
  toast-services = prev.callPackage ./toast-services { };
  # vimPlugins = prev.vimPlugins // {
  #   fidget-nvim = prev.callPackage ./fidget-nvim { };
  # };
}
