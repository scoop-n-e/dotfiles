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
    in
    {
      nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
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
