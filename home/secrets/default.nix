{ config, lib, ... }:
let
  cfg = config.my-home;
in
{
  age.secrets = {
    # Personal machine secrets
    openrouter_key = lib.mkIf (!cfg.isWork) {
      file = ../../secrets/openrouter_key.age;
    };

    # Work machine secrets
    flaggy_token = lib.mkIf cfg.isWork {
      file = ../../secrets/flaggy_token.age;
    };
  };
}
