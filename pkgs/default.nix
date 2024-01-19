final: prev:
{
  # Adding packages here, makes them accessible from "pkgs"
  braid = prev.callPackage ./braid { };
  homebridge = prev.callPackage ./homebridge { };
  homebridge-config-ui-x = prev.callPackage ./homebridge-config-ui-x { };
  nix-cleanup = prev.callPackage ./nix-cleanup { };
  oktoast = prev.callPackage ./oktoast { };
  pizzabox = prev.callPackage ./pizzabox { };
  python3Packages = prev.python3Packages // {
    toast-tools = prev.callPackage ./toast-tools { };
  };
  toast-services = prev.callPackage ./toast-services { };
  vimPlugins = prev.vimPlugins // {
    fidget-nvim = prev.callPackage ./fidget-nvim { };
  };
}
