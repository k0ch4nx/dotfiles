{ ... }:
let
  cache = import ../r2-cache.nix;
in
{
  flake-file = {
    description = "k0ch4nx dotfiles — nix-darwin + system-manager + Home Manager";

    outputs = "inputs: import ./outputs.nix inputs";

    nixConfig = {
      inherit (cache) substituters;
      trusted-public-keys = cache.trustedPublicKeys;
      fallback = true;
    };

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

      llm-agents = {
        url = "github:numtide/llm-agents.nix";
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

      spring-boot-skills = {
        url = "github:rrezartprebreza/spring-boot-skills";
        flake = false;
      };

      terminal-browser = {
        url = "github:zenbu-labs/terminal-browser";
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

      mattpocock-skills = {
        url = "github:mattpocock/skills";
        flake = false;
      };

      ecc = {
        url = "github:affaan-m/ecc";
        flake = false;
      };

      openclaw = {
        url = "github:openclaw/openclaw";
        flake = false;
      };

      autoskills = {
        url = "github:midudev/autoskills";
        flake = false;
      };

      cc-templates = {
        url = "github:davila7/claude-code-templates";
        flake = false;
      };

      google-skills = {
        url = "github:google/skills";
        flake = false;
      };

      gemini-cli = {
        url = "github:google-gemini/gemini-cli";
        flake = false;
      };

      agenix = {
        url = "github:ryantm/agenix/main";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      flake-file = {
        url = "github:denful/flake-file";
      };
    };
  };
}
