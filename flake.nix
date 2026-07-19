{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    genshijin = {
      url = "github:InterfaceX-co-jp/genshijin";
      flake = false;
    };

    natural-japanese = {
      url = "github:coji/natural-japanese";
      flake = false;
    };

    kaynetik-skills = {
      url = "github:kaynetik/skills";
      flake = false;
    };

    cloudflare-skills = {
      url = "github:cloudflare/skills";
      flake = false;
    };

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
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
    inputs:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      blueprint = inputs.blueprint {
        inherit inputs;
        prefix = "nix/";
        inherit systems;

        nixpkgs = {
          config.allowUnfree = true;
          overlays = import ./nix/overlays;
        };
      };

    in
    blueprint
    // {
      homeConfigurations."k0ch4nx@ubuntu-wsl" =
        blueprint.legacyPackages.x86_64-linux.homeConfigurations."k0ch4nx@ubuntu-wsl";

      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self;
        inherit (inputs.self) darwinConfigurations;
        inherit (inputs.self) homeConfigurations;
      };
    };
}
