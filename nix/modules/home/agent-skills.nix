{ inputs, ... }:

{
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  programs.agent-skills = {
    enable = true;

    sources = {
      anthropic-skills = {
        input = "anthropic-skills";
        subdir = "skills";
        filter.nameRegex = "frontend-design";
      };

      cloudflare-skills = {
        input = "cloudflare-skills";
        subdir = "skills";
      };

      genshijin = {
        input = "genshijin";
        subdir = "skills";
      };

      hashicorp-agent-skills = {
        input = "hashicorp-agent-skills";
        subdir = "terraform/code-generation/skills";
        filter.nameRegex = "terraform-style-guide";
      };

      i-have-adhd = {
        input = "i-have-adhd";
        subdir = "skills";
        filter.nameRegex = "i-have-adhd";
      };

      kaynetik-skills = {
        input = "kaynetik-skills";
        filter.nameRegex = "ultimate-nixos";
      };

      natural-japanese = {
        input = "natural-japanese";
        subdir = "skills";
      };

      openai-skills = {
        input = "openai-skills";
        subdir = "skills/.curated";
        filter.nameRegex = "gh-fix-ci";
      };

      superpowers = {
        input = "superpowers";
        subdir = "skills";
      };

      trailofbits-skills = {
        input = "trailofbits-skills";
        subdir = "plugins/insecure-defaults/skills";
        filter.nameRegex = "insecure-defaults";
      };
    };

    skills.enableAll = true;

    targets.codex.enable = true;
    targets.opencode.enable = true;
  };
}
