{ config, pkgs, lib, ... }:

{
  imports = [ ./modules/gpu/amd.nix ];

  system.stateVersion = "26.05";

  boot.initrd.systemd.enable = true; # 26.05のデフォルトtrueを明示(計画書§2.9)
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-desktop";
  networking.networkmanager.enable = true;

  users.users.scoop = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
  };

  # サスペンド/復帰対策(suspend_fan_issue_investigation_20260719.md 0.8節・31節、欠落厳禁)。
  boot.kernelParams = [ "radeon.dpm=0" ];

  # 起動時1回のみ適用。元Arch実装(...part4.md 32.4節)でコールドブート跨ぎ3回込み8回連続成功実績あり、
  # サスペンド/復帰の都度の再適用は不要と確認済み。card0固定は避けglobで解決する。
  systemd.services.radeon-power-profile = {
    description = "radeon power profile low";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for f in /sys/class/drm/card*/device/power_profile; do
        [ -e "$f" ] && echo low > "$f"
      done
    '';
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true; # SDDMグリーター自体のWayland描画(experimental)
  services.displayManager.defaultSession = "plasma"; # plasma6モジュール自身のmkDefaultと同値(2026-07-20 nixpkgsソース確認済み)

  # 【案B】自動ログイン。DEを変更する場合はこの2行も合わせて書き換えること。
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "scoop";

  i18n.defaultLocale = "en_US.UTF-8"; # 英語UI+日本語入力
  i18n.extraLocales = [ "ja_JP.UTF-8/UTF-8" ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc-ut fcitx5-gtk ];
    # falseのままだとモジュール自身がGTK_IM_MODULE/QT_IM_MODULEを設定してしまう
    # (2026-07-20、nixpkgsのfcitx5.nixモジュールソースで確認済み)。Chrome+Wayland
    # ではネイティブtext-inputプロトコルと衝突するためtrueにする。
    fcitx5.waylandFrontend = true;
  };
  # XMODIFIERS="@im=fcitx" はfcitx5モジュール自身が常に設定するため、ここで重複指定しない。

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji # 旧 noto-fonts-emoji は廃止済み(2026-07-20 nixpkgs unstableで確認)
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans CJK JP" ]; # "JP"指定必須、無指定だと中華フォント優先になる既知問題あり
    serif = [ "Noto Serif CJK JP" ];
    emoji = [ "Noto Color Emoji" ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "google-chrome" "claude-code" ];

  environment.systemPackages = with pkgs; [
    google-chrome
    (pkgs.callPackage ./pkgs/claude-code.nix { })
  ];

  services.openssh.enable = true;

  # 公式インストーラ配布の未パッチ動的リンクバイナリ用の退避路(claude-code自前derivationが
  # 壊れた場合用)。不足ライブラリは実機で確認しながら追記する運用(計画書§3参照)。
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [ ];
}
