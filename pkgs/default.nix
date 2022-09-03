final: prev:

{
  nvim-ts-grammars = prev.callPackage ./nvim-ts-grammars { };
  oktoast = prev.callPackage ./oktoast { };
  pizzabox = prev.callPackage ./pizzabox { };
  python3Packages = prev.python3Packages // {
    jsons = prev.callPackage ./jsons { };
  };
  # sumneko-lua-language-server = prev.callPackage ./sumneko-lua-language-server { };
  toast-services = prev.callPackage ./toast-services { };
  vimPlugins = prev.vimPlugins // {
    gitsigns-nvim-fixed = prev.callPackage ./gitsigns-nvim-fixed { };
  };
}