# Home Manager最小構成(2026-07-20時点)。
# 注意: mcp-nixosのhome-managerデータソースがこのセッションでは機能しなかった(統計取得もエラー)ため、
# home.stateVersion・programs.git.enableはMCP裏取りなし(長年安定している基礎オプションとして採用)。
# 拡張時はhome-managerのデータソースが復旧してから改めて確認すること。
{ ... }:

{
  home.stateVersion = "26.05"; # system.stateVersionと同値、永久固定(計画書§2.6)

  programs.git.enable = true;
}
