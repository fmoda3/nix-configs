_: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "nixos";
              start = "512MiB";
              end = "-8GiB";
              part-type = "primary";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
            {
              name = "swap";
              start = "-8GiB";
              end = "100%";
              part-type = "primary";
              fs-type = "linux-swap";
              content = {
                type = "swap";
              };
            }
            {
              name = "ESP";
              start = "1MiB";
              end = "512MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
          ];
        };
      };
    };
  };
}
