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
      };

      mattpocock-skills = {
        input = "mattpocock-skills";
        subdir = "skills";
      };

      cloudflare-skills = {
        input = "cloudflare-skills";
        subdir = "skills";
      };

      dotnet-skills = {
        input = "dotnet-skills";
        subdir = "plugins";
      };

      kiro-skills = {
        input = "kiro-skills";
        subdir = "skills";
      };

      critique = {
        input = "gemini-cli";
        subdir = "tools/gemini-cli-bot/.gemini/skills";
      };

      ecc = {
        input = "ecc";
        subdir = "skills";
        idPrefix = "ecc";
      };

      openclaw-github = {
        input = "openclaw";
        subdir = "skills";
      };

      svelte5-best-practices = {
        input = "autoskills";
        subdir = "packages/autoskills/skills-registry";
      };

      terraform-module-library = {
        input = "wshobson-agents";
        subdir = "plugins/cloud-infrastructure/skills";
      };

      terraform-specialist = {
        input = "cc-templates";
        subdir = "cli-tool/components/skills/development";
      };

      google-cloud = {
        input = "google-skills";
        subdir = "skills/cloud";
      };

      dot-skills = {
        input = "dot-skills";
        subdir = "skills/.experimental";
      };

      genshijin = {
        input = "genshijin";
        subdir = "skills";
      };

      hashicorp-agent-skills = {
        input = "hashicorp-agent-skills";
        subdir = "plugins/terraform/skills";
      };

      i-have-adhd = {
        input = "i-have-adhd";
        subdir = "skills";
      };

      kaynetik-skills = {
        input = "kaynetik-skills";
      };

      natural-japanese = {
        input = "natural-japanese";
        subdir = "skills";
      };

      yomiyasu = {
        input = "yomiyasu";
        subdir = "skills";
      };

      openai-skills = {
        input = "openai-skills";
        subdir = "skills/.curated";
      };

      spring-boot-skills = {
        input = "spring-boot-skills";
        subdir = "skills/spring-boot-4";
      };

      terminal-browser = {
        input = "terminal-browser";
        subdir = "skill";
      };

      superpowers = {
        input = "superpowers";
        subdir = "skills";
      };

      wshobson-agents = {
        input = "wshobson-agents";
        subdir = "plugins/shell-scripting/skills";
      };
    };

    skills.enable = [
      "frontend-design"
      "gh-fix-ci"
      "ultimate-nixos"
    ];

    targets.opencode.enable = true;
  };
}
