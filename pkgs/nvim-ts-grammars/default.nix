{ lib, stdenv, tree-sitter, nodejs, fetchgit, callPackage }:

let
  fetchGrammar = (v: fetchgit { inherit (v) url rev sha256 fetchSubmodules; });
  builtGrammars =
    let
      change = name: grammar:
        callPackage ./grammar.nix { } {
          language = if grammar ? language then grammar.language else name;
          version = tree-sitter.version;
          source = fetchGrammar grammar;
          location = if grammar ? location then grammar.location else null;
        };
      grammars' = (import ./grammars);
      grammars = grammars' //
        { tree-sitter-ocaml = grammars'.tree-sitter-ocaml // { location = "ocaml"; }; } //
        { tree-sitter-ocaml-interface = grammars'.tree-sitter-ocaml // { location = "interface"; }; } //
        { tree-sitter-typescript = grammars'.tree-sitter-typescript // { location = "typescript"; }; } //
        { tree-sitter-tsx = grammars'.tree-sitter-typescript // { location = "tsx"; }; };
    in
    lib.mapAttrs change grammars;
  allGrammars = builtins.attrValues builtGrammars;
in { inherit builtGrammars allGrammars; }