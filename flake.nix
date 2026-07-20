{
  description = "NixOS configuration for nixos-desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }:
    let
      system = "x86_64-linux";
      # claude-codeはunfreeライセンスのため、flakeのpackages出力用にも明示的に許可する必要がある
      # (configuration.nix側のallowUnfreePredicateはNixOSシステム内部のpkgsにしか効かない。
      # 2026-07-20、nix flake checkの実エラーで判明)。
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
      };

      commonModules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        ./disk-config.nix
        ./hardware-configuration.nix
        ./configuration.nix
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.scoop = import ./home.nix;
        }
      ];
    in
    {
      nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules;
      };

      # VM起動確認専用(手順書0.3参照)。system.build.vmは仮想ディスクを自動生成するが、
      # diskoが配線するswapDevices/fileSystems(/home等、実機のLUKSデバイス参照)はVM内に
      # 存在しないため、素の設定のままだと起動がそこで無期限に停止する(disko/VMの既知の相互作用)。
      # disko.enableConfig=false(disko公式のVMテスト向けオプション)でその自動配線を止め、
      # VM自身のディスクのみで完結させる。本番用nixos-desktopには一切影響しない。
      # メモリ/コース数はデフォルト(1024MB・1コア)だとPlasma6+Chromeがもたつくため引き上げる
      # (ホスト実機はRyzen 7 5700X 8C/16T・RAM32GBのため余裕あり)。
      nixosConfigurations.nixos-desktop-vmtest = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ [
          {
            disko.enableConfig = false;
            virtualisation.memorySize = 8192;
            virtualisation.cores = 6;
          }
        ];
      };

      packages.${system} = {
        # diskoのflakeはapps出力を持たずpackagesのみ(2026-07-20実機確認済み)。
        # flake.lockでピン留めされたリビジョンをそのまま使うため、
        # github:nix-community/disko/latest を直接叩かずここ経由で実行する(手順書2.5参照)。
        disko = disko.packages.${system}.disko;
        claude-code = pkgs.callPackage ./pkgs/claude-code.nix { };
      };
    };
}
