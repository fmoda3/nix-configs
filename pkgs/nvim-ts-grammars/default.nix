{ lib, stdenv, tree-sitter, fetchgit, callPackage }:

let
  fetchGrammar = (v: fetchgit { inherit (v) url rev sha256 fetchSubmodules; });
  builtGrammars = let
    buildGrammar = name: grammar:
      callPackage ./grammar.nix { } {
        language = name;
        version = tree-sitter.version;
        source = fetchGrammar grammar;
        location = if grammar ? location then grammar.location else null;
      };

    grammars' = (import ./grammars);
    grammars = grammars' // {
      tree-sitter-ocaml = grammars'.tree-sitter-ocaml // {
        location = "ocaml";
      };
    } // {
      tree-sitter-ocaml_interface = grammars'.tree-sitter-ocaml // {
        location = "interface";
      };
    } // {
      tree-sitter-typescript = grammars'.tree-sitter-typescript // {
        location = "typescript";
      };
    } // {
      tree-sitter-tsx = grammars'.tree-sitter-typescript // {
        location = "tsx";
      };
    };
  in lib.mapAttrs buildGrammar grammars;
  allGrammars = builtins.attrValues builtGrammars;
in { inherit builtGrammars allGrammars; }