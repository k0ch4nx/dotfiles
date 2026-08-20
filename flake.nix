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
      url = "github:anthropics/skills";
      flake = false;
    };
    autoskills = {
      url = "github:midudev/autoskills";
      flake = false;
    };
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cc-templates = {
      url = "github:davila7/claude-code-templates";
      flake = false;
    };
    cloudflare-skills = {
      url = "github:cloudflare/skills";
      flake = false;
    };
    dot-skills = {
      url = "github:pproenca/dot-skills";
      flake = false;
    };
    ecc = {
      url = "github:affaan-m/ecc";
      flake = false;
    };
    flake-file.url = "github:denful/flake-file";
    gemini-cli = {
      url = "github:google-gemini/gemini-cli";
      flake = false;
    };
    genshijin = {
      url = "github:InterfaceX-co-jp/genshijin";
      flake = false;
    };
    google-skills = {
      url = "github:google/skills";
      flake = false;
    };
    hashicorp-agent-skills = {
      url = "github:hashicorp/agent-skills";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-jackielii-tap = {
      url = "github:jackielii/homebrew-tap";
      flake = false;
    };
    i-have-adhd = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };
    kaynetik-skills = {
      url = "github:kaynetik/skills";
      flake = false;
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    natural-japanese = {
      url = "github:coji/natural-japanese";
      flake = false;
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openai-skills = {
      url = "github:openai/skills";
      flake = false;
    };
    openclaw = {
      url = "github:openclaw/openclaw";
      flake = false;
    };
    spring-boot-skills = {
      url = "github:rrezartprebreza/spring-boot-skills";
      flake = false;
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terminal-browser = {
      url = "github:zenbu-labs/terminal-browser";
      flake = false;
    };
    trailofbits-skills = {
      url = "github:trailofbits/skills";
      flake = false;
    };
    wshobson-agents = {
      url = "github:wshobson/agents";
      flake = false;
    };
  };
}
