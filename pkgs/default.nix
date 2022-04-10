final: prev:

with prev;
{
  nvim-ts-grammars = callPackage ./nvim-ts-grammars { };
  oktoast = callPackage ./oktoast { };
  pizzabox = callPackage ./pizzabox { };
  python3Packages = python3Packages // {
    jsons = callPackage ./jsons { };
    typish = callPackage ./typish { };
  };
  toast-services = prev.callPackage ./toast-services { };
  vimPlugins = vimPlugins // {
    cmp-nvim-lsp-signature-help = callPackage ./cmp-nvim-lsp-signature-help {
      inherit (vimUtils) buildVimPluginFrom2Nix;
    };
    legendary-nvim = callPackage ./legendary-nvim {
      inherit (vimUtils) buildVimPluginFrom2Nix;
    };
  };
}