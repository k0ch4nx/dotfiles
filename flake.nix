# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "k0ch4nx dotfiles — nix-darwin + system-manager + Home Manager";

  outputs = inputs: import ./outputs.nix inputs;

  nixConfig = {
    fallback = true;
    substituters = [
      "https://cache.nixos.org/?priority=10"
      "https://nix-community.cachix.org?priority=20"
      "https://cache.numtide.com?priority=25"
      "s3://nix-cache?endpoint=6118f982b348f7b37129655ee4160301.r2.cloudflarestorage.com&scheme=https&region=auto&priority=30"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-cache-local:GpHBxUjXDkgtfjKeAD/cuGY8pnCjSsZhc8plkslpfFk="
      "nix-cache-ci:8fZtfHt16O6CvXJlPH0H4uqHTs61K5iruLvTAIFIPmU="
    ];
  };

  inputs = {
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    anthropic-skills = {
      url = "git+https://github.com/anthropics/skills.git?shallow=1";
      flake = false;
    };
    autoskills = {
      url = "git+https://github.com/midudev/autoskills.git?shallow=1";
      flake = false;
    };
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cc-templates = {
      url = "git+https://github.com/davila7/claude-code-templates.git?shallow=1";
      flake = false;
    };
    cloudflare-skills = {
      url = "git+https://github.com/cloudflare/skills.git?shallow=1";
      flake = false;
    };
    dot-skills = {
      url = "git+https://github.com/pproenca/dot-skills.git?shallow=1";
      flake = false;
    };
    dotnet-skills = {
      url = "git+https://github.com/dotnet/skills.git?shallow=1";
      flake = false;
    };
    ecc = {
      url = "git+https://github.com/affaan-m/ecc.git?shallow=1";
      flake = false;
    };
    flake-file.url = "github:denful/flake-file";
    gemini-cli = {
      url = "git+https://github.com/google-gemini/gemini-cli.git?shallow=1";
      flake = false;
    };
    genshijin = {
      url = "git+https://github.com/InterfaceX-co-jp/genshijin.git?shallow=1";
      flake = false;
    };
    google-skills = {
      url = "git+https://github.com/google/skills.git?shallow=1";
      flake = false;
    };
    hashicorp-agent-skills = {
      url = "git+https://github.com/hashicorp/agent-skills.git?shallow=1";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-jackielii-tap = {
      url = "git+https://github.com/jackielii/homebrew-tap.git?shallow=1";
      flake = false;
    };
    i-have-adhd = {
      url = "git+https://github.com/ayghri/i-have-adhd.git?shallow=1";
      flake = false;
    };
    kaynetik-skills = {
      url = "git+https://github.com/kaynetik/skills.git?shallow=1";
      flake = false;
    };
    kiro-skills = {
      url = "git+https://github.com/jasonkneen/kiro.git?shallow=1";
      flake = false;
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    mattpocock-skills = {
      url = "git+https://github.com/mattpocock/skills.git?shallow=1";
      flake = false;
    };
    natural-japanese = {
      url = "git+https://github.com/coji/natural-japanese.git?shallow=1";
      flake = false;
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openai-skills = {
      url = "git+https://github.com/openai/skills.git?shallow=1";
      flake = false;
    };
    openclaw = {
      url = "git+https://github.com/openclaw/openclaw.git?shallow=1";
      flake = false;
    };
    spring-boot-skills = {
      url = "git+https://github.com/rrezartprebreza/spring-boot-skills.git?shallow=1";
      flake = false;
    };
    superpowers = {
      url = "git+https://github.com/obra/superpowers.git?shallow=1";
      flake = false;
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terminal-browser = {
      url = "git+https://github.com/zenbu-labs/terminal-browser.git?shallow=1";
      flake = false;
    };
    trailofbits-skills = {
      url = "git+https://github.com/trailofbits/skills.git?shallow=1";
      flake = false;
    };
    wshobson-agents = {
      url = "git+https://github.com/wshobson/agents.git?shallow=1";
      flake = false;
    };
  };
}
