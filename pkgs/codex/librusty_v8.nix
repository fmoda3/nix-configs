# auto-generated file -- DO NOT EDIT!
{ fetchLibrustyV8, fetchRustyV8Binding }:
let
  version = "150.4.0";
in
{
  archive = fetchLibrustyV8 {
    inherit version;
    shas = {
      x86_64-linux = "sha256-o1x10fJuapg4haRbM0kKTr5U8FBQVosyuJz7QhswtYM=";
      aarch64-linux = "sha256-0VF+7UBUaFNwKbAF1f6ZfsdNXI01H5FrOm3yC30oEbo=";
      x86_64-darwin = "sha256-4Nm7ZOizoDTCkwyDly8/NXYCERSDQvoEB7OCUO8zCFY=";
      aarch64-darwin = "sha256-AK27SHmISMd1UEQcaGc6XoUpuOG3PqvN7iMss5tA9KE=";
    };
  };

  binding = fetchRustyV8Binding {
    inherit version;
    shas = {
      x86_64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
      aarch64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
      x86_64-darwin = "sha256-ylrfDPicmnCtRgrnNkiy/om3SqETs8t/dXtqArdYOU8=";
      aarch64-darwin = "sha256-ylrfDPicmnCtRgrnNkiy/om3SqETs8t/dXtqArdYOU8=";
    };
  };
}
