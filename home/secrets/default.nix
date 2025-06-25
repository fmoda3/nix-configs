{ config, lib, ... }:
with lib;
let
  cfg = config.my-home;
in
{
  age.secrets = {
    # Global secrets available on all machines
    anthropic_ai_key.file = ../../secrets/anthropic_ai_key.age;
    openrouter_key.file = ../../secrets/openrouter_key.age;

    # Personal machine secrets (when not work)
    personal_github_key = mkIf (!cfg.isWork) {
      file = ../../secrets/personal_github_key.age;
    };

    # Work machine secrets
    flaggy_token = mkIf cfg.isWork {
      file = ../../secrets/flaggy_token.age;
    };

    work_github_key = mkIf cfg.isWork {
      file = ../../secrets/work_github_key.age;
    };
  };
}
