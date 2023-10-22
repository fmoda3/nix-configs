# This file is not imported into your NixOS configuration. It is only used for the agenix CLI.
# agenix use the public keys defined in this file to encrypt the secrets.
# and users can decrypt the secrets by any of the corresponding private keys.

let
  # get user's ssh public key by command:
  #     cat ~/.ssh/id_ed25519.pub
  # if you do not have one, you can generate it by command:
  #     ssh-keygen -t ed25519
  cicucci-laptop-fmoda3 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCz3Wfp4pIEqpgegM4FCrEiehQEnwDXmTQmpL2+QUKerDQEep3bJYS2NKqHeMotuCgSjbhnObPPxpT7Vr8bq/NFdfLbuqFILx7mCCmzvWB3A050qQkwLuE00PEYmdsH25OhztgTMPvHMhtw1gNJCAyXtvI3DN0DCJKDRJFWOp/Kj70hxHNsQogPbBBgqzfF4j2aYC7X7h3bXHzOc4lKFhZ+7xIj0yGenSSw9PM9PUvEMlFL53uG4QsUisIOvs7IptXjOkdWAug/bRX+XpEFYmCEp+1H2UqZVRNmIV6Fa2FPXqRILuWOsCALmYV5oRk9MgPbufdJ9CHvmu1SMCJ/mlbt8jicmOvgdzdRBmYiWfjtZNh929pP8c9BgFCNt4efZ5qqynlUzywuO4agw1iOXi4KppPLbb7UisnMo9+NtEjHXtneRJnPgYi+KmNyS/7O1/9egDt64bB9+ZkGjajeOVELxcEvwrHupHeLb3N3gC7lkAoRwmGHWxHKcyDS6kUQRC0=";
  users = [ cicucci-laptop-fmoda3 ];

  # get system's ssh public key by command:
  #    cat /etc/ssh/ssh_host_ed25519_key.pub
  cicucci-dns = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfR61TZ2/54tN4NJXhp9+NJRw0gIELXm0c+nzpACLKo";
  systems = [ cicucci-dns ];

  all = users ++ systems;
in
{
  "dns_tailscale_key.age".publicKeys = all;
}
