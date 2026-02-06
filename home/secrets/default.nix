{ config, lib, ... }:
let
  cfg = config.my-home;
in
{
  age.secrets = {
    # Work machine secrets
    flaggy_token = lib.mkIf cfg.isWork {
      file = ../../secrets/flaggy_token.age;
    };
  };
}
