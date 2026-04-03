{ config, ... }:
{
  programs.awscli = {
    enable = config.my-home.isWork;

    settings = {
      "default" = {
        region = "us-east-1";
      };
      "sso-session default" = {
        sso_start_url = "https://d-90661e9ac4.awsapps.com/start";
        sso_region = "us-east-1";
        sso_registration_scopes = "sso:account:access";
      };
    };
  };
}
