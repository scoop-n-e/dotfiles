# 未使用のNvidia雛形(2026-07-20 mcp-nixos裏取り、channel=unstable)。
# 切り替える場合、configuration.nixのimportsで ./modules/gpu/amd.nix をこれに差し替え、
# 以下のコメントを外して調整する。
#
# 注意: 計画書が「26.05新設」としていた hardware.nvidia.branch は、
# unstableチャンネルの実オプション一覧に存在しないことを確認済み(誤記録)。使わないこと。
{ config, lib, pkgs, ... }:

{
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.open = false; # プロプライエタリドライバ。対応世代ならtrueも検討可
  # nixpkgs.config.allowUnfreePredicate = pkg:
  #   builtins.elem (lib.getName pkg) [ "nvidia-x11" "nvidia-settings" ];
}
