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
              type = "partition";
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
              type = "partition";
              start = "-8GiB";
              end = "100%";
              part-type = "primary";
              content = {
                type = "swap";
              };
            }
            {
              name = "ESP";
              type = "partition";
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
