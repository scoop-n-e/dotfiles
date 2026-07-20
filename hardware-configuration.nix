# プレースホルダ。Phase 2.7でライブ環境の `nixos-generate-config --no-filesystems` により
# 実機生成した内容に差し替える(手順書2.7参照)。fileSystemsはdisko(disk-config.nix)が供給するため
# ここには書かない。
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
