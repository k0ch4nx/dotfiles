{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      agenix,
      agenix-rekey,
      ...
    }:
    let
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./nix/hosts/MacBook-Pro
        ];
      };

      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        inherit (self) darwinConfigurations;
      };
    };
}
