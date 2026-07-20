{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G3_SSD_5FSKF21HZ0EA";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            # 末尾34G(swap用)を残し、それ以外すべてをrootに割り当てる。
            # ディスク実容量の事前計算(blockdev --getsize64)は不要(disko側のend相対指定に委ねる)。
            root = {
              end = "-34G";
              content = {
                type = "luks";
                name = "cryptroot";
                passwordFile = "/tmp/disk.key";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-m" "dup" ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" ];
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" ];
                    };
                  };
                };
              };
            };

            # size = "100%" で末尾までを確保し、GPT整列等の端数を吸収して34G以上を保証する。
            swap = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptswap";
                passwordFile = "/tmp/disk.key";
                settings.allowDiscards = true;
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
