final: prev:

{
  nvim-ts-grammars = prev.callPackage ./nvim-ts-grammars { };
  oktoast = prev.callPackage ./oktoast { };
  vimPlugins = prev.vimPlugins // {
    cmp-nvim-lsp-signature-help = prev.callPackage ./cmp-nvim-lsp-signature-help { };
    legendary-nvim = prev.callPackage ./legendary-nvim { };
    nord-vim = prev.callPackage ./nord-vim { };
  };
}