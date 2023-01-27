final: prev:

{
  braid = prev.callPackage ./braid { };
  nvim-ts-grammars = prev.callPackage ./nvim-ts-grammars { };
  oktoast = prev.callPackage ./oktoast { };
  pizzabox = prev.callPackage ./pizzabox { };
  python3Packages = prev.python3Packages // {
    toast-tools = prev.callPackage ./toast-tools { };
  };
  toast-services = prev.callPackage ./toast-services { };
  # vimPlugins = prev.vimPlugins // {
  #   gitsigns-nvim = prev.callPackage ./gitsigns-nvim { };
  # };
}
