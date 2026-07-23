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

    homebrew-jackielii-tap = {
      url = "github:jackielii/homebrew-tap";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    system-manager = {
      url = "github:numtide/system-manager";
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

    dot-skills = {
      url = "github:pproenca/dot-skills";
      flake = false;
    };

    wshobson-agents = {
      url = "github:wshobson/agents";
      flake = false;
    };

    i-have-adhd = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };

    hashicorp-agent-skills = {
      url = "github:hashicorp/agent-skills";
      flake = false;
    };

    openai-skills = {
      url = "github:openai/skills";
      flake = false;
    };

    trailofbits-skills = {
      url = "github:trailofbits/skills";
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
      cacheSettings = import ./nix/r2-cache.nix;

      darwinConfigurations = blueprint.darwinConfigurations // {
        cache-bootstrap = inputs.nix-darwin.lib.darwinSystem {
          modules = [ ./nix/cache-bootstrap/darwin.nix ];
          specialArgs = {
            flake = inputs.self;
            inherit inputs;
            hostName = "macbook-pro";
          };
        };
      };

      systemConfigs = blueprint.systemConfigs // {
        cache-bootstrap = inputs.system-manager.lib.makeSystemConfig {
          modules = [ ./nix/cache-bootstrap/wsl.nix ];
          extraSpecialArgs = {
            flake = inputs.self;
            inherit inputs;
            hostName = "ubuntu-wsl";
          };
        };
      };

      homeConfigurations."k0ch4nx@ubuntu-wsl" =
        blueprint.legacyPackages.x86_64-linux.homeConfigurations."k0ch4nx@ubuntu-wsl";

      agenix-rekey =
        (inputs.agenix-rekey.configure {
          userFlake = inputs.self;

          darwinConfigurations = {
            inherit (inputs.self.darwinConfigurations) cache-bootstrap macbook-pro;
          };

          systems = [
            "aarch64-darwin"
          ];
        })
        // (inputs.agenix-rekey.configure {
          userFlake = inputs.self;

          nixosConfigurations = {
            inherit (inputs.self.systemConfigs) cache-bootstrap ubuntu-wsl;
          };

          homeConfigurations = {
            inherit (inputs.self.homeConfigurations) "k0ch4nx@ubuntu-wsl";
          };

          systems = [
            "x86_64-linux"
          ];
        });
    };
}
