# NixOS Configuration Flake
# Host: nullrunner (Framework 16-inch AMD AI 300 series)

{
  description = "NixOS configuration for nullrunner";

  inputs = {
    # Package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware-specific modules (Framework laptop)
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home manager for user environment
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative neovim configuration
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Consistent theming engine
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spicetify for Spotify theming
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nixvim, stylix, spicetify-nix }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NixOS system configuration
      nixosConfigurations.nullrunner = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Hardware configuration
          nixos-hardware.nixosModules.framework-16-amd-ai-300-series
          
          # System configuration
          ./hosts/nullrunner
          
          # Stylix theming
          stylix.nixosModules.stylix
          
          # Home manager as NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.westonw = import ./home/westonw;
            home-manager.extraSpecialArgs = { inherit inputs; inherit (inputs) spicetify-nix; };
          }
        ];
      };
    };
}
