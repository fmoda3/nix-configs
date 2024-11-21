# This file is not imported into your NixOS configuration. It is only used for the agenix CLI.
# agenix use the public keys defined in this file to encrypt the secrets.
# and users can decrypt the secrets by any of the corresponding private keys.

let
  # get user's ssh public key by command:
  #     cat ~/.ssh/id_ed25519.pub
  # if you do not have one, you can generate it by command:
  #     ssh-keygen -t ed25519
  cicucci-imac-fmoda3 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCffzb1fCJTkGnzGp7y/2jJp+Ra96FJKdAQgeeAXgZOl7rXWsI+2OOrsUNyRs729huVtX2vN4bGO4ICu2RD2vUnxnmoqagcn+xqnyZDL4JNjUeOpuQtfgcQJaAHrFCqhy5WbNYzNljrR99vTseQvfz0LkCuH3IsPqKSykystBEACb6BkAC+xdx7Ysy89L7Yxbi4tNI+LMB2qPI3/x+jQTQdzdMRxd6Jp7u7LLwjSwWIEsKxtHDfR3QzWkhlziT3kWdc3ydtPfAG/TjTh231UFKi0WmTH80UeLyip0kE1/HGUoVIZIxD+gf1T2mBF/pVEr66lkITuQS/Fp1Bq0LrLGtPgb3Mv82CHEnpzTqpXdaE9rc014bORT0/J11clMYt+PbO38iy9oFaWpW0Yh6ucyPaftrh8Td5K2UAwAHur+y+e4r8XhGpBN7WIxPnR/sD+pScyPEsECGmVp4DCxXEe+es1q5W42O2GcWiUwezvQqO3fY4JVoZaWsIRv6Btoh4ZHU=";
  cicucci-laptop-fmoda3 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCz3Wfp4pIEqpgegM4FCrEiehQEnwDXmTQmpL2+QUKerDQEep3bJYS2NKqHeMotuCgSjbhnObPPxpT7Vr8bq/NFdfLbuqFILx7mCCmzvWB3A050qQkwLuE00PEYmdsH25OhztgTMPvHMhtw1gNJCAyXtvI3DN0DCJKDRJFWOp/Kj70hxHNsQogPbBBgqzfF4j2aYC7X7h3bXHzOc4lKFhZ+7xIj0yGenSSw9PM9PUvEMlFL53uG4QsUisIOvs7IptXjOkdWAug/bRX+XpEFYmCEp+1H2UqZVRNmIV6Fa2FPXqRILuWOsCALmYV5oRk9MgPbufdJ9CHvmu1SMCJ/mlbt8jicmOvgdzdRBmYiWfjtZNh929pP8c9BgFCNt4efZ5qqynlUzywuO4agw1iOXi4KppPLbb7UisnMo9+NtEjHXtneRJnPgYi+KmNyS/7O1/9egDt64bB9+ZkGjajeOVELxcEvwrHupHeLb3N3gC7lkAoRwmGHWxHKcyDS6kUQRC0=";
  cicucci-homelab-fmoda3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbsadR1/6wz//uJ7fjuQnyBd3shjFcaLl5wlhSaFD+4";
  work-laptop-fmoda3 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYl3aVZjHTsKEboUS7r1YYAPdb39SKiIz1VtIVTLARR1goxg34Zbq0drxYyToBD151UmQ8Rs8Ybv3WVYQISdp9j4B8ZVjijLdL1SyajMAOztz5/3vlbEU9+tZUnd9VxEi7bRB31uFpaAjCYghHDaY22S8UzRqg0xZfQc/MEa7rgbXP1gxEeolEOJYohSk6ko3X6yAW15vd8mmJCThbtYbLkp31Yhdbo0KnyBIQo7or8IK5qbjHFdMwveYh29QXur7fZ+bDvFWUvW6DnrBkvMSZAymDACiOYUOenqmmdIhzyC3QN2RosABF3tB2rBkPb4WhfTQbyx8mYSZLkl5mUuGhMD0wXhmmcaoRV3miT807D1lDe9+bxcXnZEQSzTpPUQMgm12F2LkWnF7eZDTHcVZRhYUxrepHFHl7pq2N50LVq5ThNF+KImc1yqb7X0646cHibn9TxB2lKN8miACdepGMyNYfNmuJVxyoHh9y2MNhUohFc6QwvaEUtjFgj1jJtW8=";
  users = [ cicucci-imac-fmoda3 cicucci-laptop-fmoda3 cicucci-homelab-fmoda3 work-laptop-fmoda3 ];

  # get system's ssh public key by command:
  #    cat /etc/ssh/ssh_host_ed25519_key.pub
  cicucci-dns = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfR61TZ2/54tN4NJXhp9+NJRw0gIELXm0c+nzpACLKo";
  cicucci-homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjpYheKaxVXLCQH4hQ2Y9uCmWuWfHPaWwEaVovNr2Am";
  systems = [ cicucci-dns cicucci-homelab ];

  all = users ++ systems;
in
{
  "codestral_ai_key.age".publicKeys = all;
  "dns_tailscale_key.age".publicKeys = all;
  "homelab_tailscale_key.age".publicKeys = all;
  "flaggy_token.age".publicKeys = all;
  "mistral_ai_key.age".publicKeys = all;
  "openrouter_key.age".publicKeys = all;
  "voyage_ai_key.age".publicKeys = all;
}
