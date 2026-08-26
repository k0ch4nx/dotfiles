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
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
        url = "git+https://github.com/jackielii/homebrew-tap.git?shallow=1";
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
        url = "git+https://github.com/InterfaceX-co-jp/genshijin.git?shallow=1";
        flake = false;
      };

      natural-japanese = {
        url = "git+https://github.com/coji/natural-japanese.git?shallow=1";
        flake = false;
      };

      dot-skills = {
        url = "git+https://github.com/pproenca/dot-skills.git?shallow=1";
        flake = false;
      };

      wshobson-agents = {
        url = "git+https://github.com/wshobson/agents.git?shallow=1";
        flake = false;
      };

      i-have-adhd = {
        url = "git+https://github.com/ayghri/i-have-adhd.git?shallow=1";
        flake = false;
      };

      hashicorp-agent-skills = {
        url = "git+https://github.com/hashicorp/agent-skills.git?shallow=1";
        flake = false;
      };

      openai-skills = {
        url = "git+https://github.com/openai/skills.git?shallow=1";
        flake = false;
      };

      trailofbits-skills = {
        url = "git+https://github.com/trailofbits/skills.git?shallow=1";
        flake = false;
      };

      kaynetik-skills = {
        url = "git+https://github.com/kaynetik/skills.git?shallow=1";
        flake = false;
      };

      cloudflare-skills = {
        url = "git+https://github.com/cloudflare/skills.git?shallow=1";
        flake = false;
      };

      dotnet-skills = {
        url = "git+https://github.com/dotnet/skills.git?shallow=1";
        flake = false;
      };

      spring-boot-skills = {
        url = "git+https://github.com/rrezartprebreza/spring-boot-skills.git?shallow=1";
        flake = false;
      };

      terminal-browser = {
        url = "git+https://github.com/zenbu-labs/terminal-browser.git?shallow=1";
        flake = false;
      };

      superpowers = {
        url = "git+https://github.com/obra/superpowers.git?shallow=1";
        flake = false;
      };

      anthropic-skills = {
        url = "git+https://github.com/anthropics/skills.git?shallow=1";
        flake = false;
      };

      mattpocock-skills = {
        url = "git+https://github.com/mattpocock/skills.git?shallow=1";
        flake = false;
      };

      ecc = {
        url = "git+https://github.com/affaan-m/ecc.git?shallow=1";
        flake = false;
      };

      openclaw = {
        url = "git+https://github.com/openclaw/openclaw.git?shallow=1";
        flake = false;
      };

      autoskills = {
        url = "git+https://github.com/midudev/autoskills.git?shallow=1";
        flake = false;
      };

      cc-templates = {
        url = "git+https://github.com/davila7/claude-code-templates.git?shallow=1";
        flake = false;
      };

      google-skills = {
        url = "git+https://github.com/google/skills.git?shallow=1";
        flake = false;
      };

      gemini-cli = {
        url = "git+https://github.com/google-gemini/gemini-cli.git?shallow=1";
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
