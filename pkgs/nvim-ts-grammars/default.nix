{ lib, stdenv, tree-sitter, nodejs, fetchgit, callPackage }:

let
  fetchGrammar = v: fetchgit { inherit (v) url rev sha256 fetchSubmodules; };
  builtGrammars =
    let
      change = name: grammar:
        callPackage ./grammar.nix { } {
          language = if grammar ? language then grammar.language else name;
          inherit (tree-sitter) version;
          source = fetchGrammar grammar;
          location = if grammar ? location then grammar.location else null;
        };
      grammars' = import ./grammars;
      grammars = grammars' //
        { tree-sitter-markdown = grammars'.tree-sitter-markdown // { location = "tree-sitter-markdown"; }; } //
        { tree-sitter-markdown_inline = grammars'.tree-sitter-markdown_inline // { location = "tree-sitter-markdown-inline"; }; } //
        { tree-sitter-ocaml = grammars'.tree-sitter-ocaml // { location = "ocaml"; }; } //
        { tree-sitter-ocaml_interface = grammars'.tree-sitter-ocaml // { location = "interface"; }; } //
        { tree-sitter-typescript = grammars'.tree-sitter-typescript // { location = "typescript"; }; } //
        { tree-sitter-tsx = grammars'.tree-sitter-typescript // { location = "tsx"; }; } //
        { tree-sitter-v = grammars'.tree-sitter-v // { location = "tree_sitter_v"; }; };
    in
    lib.mapAttrs change grammars;
  allGrammars = builtins.attrValues builtGrammars;
in { inherit builtGrammars allGrammars; }