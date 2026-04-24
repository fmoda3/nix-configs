{ buildPiExtension }:

buildPiExtension {
  pname = "pi-direnv";
  version = "0.1.0";

  src = ./extension;
}
