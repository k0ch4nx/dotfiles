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
        idPrefix = "anthropic-skills";
        subdir = "skills";
      };

      mattpocock-skills = {
        input = "mattpocock-skills";
        idPrefix = "mattpocock-skills";
        subdir = "skills";
      };

      cloudflare-skills = {
        input = "cloudflare-skills";
        idPrefix = "cloudflare-skills";
        subdir = "skills";
      };

      dotnet-skills = {
        input = "dotnet-skills";
        idPrefix = "dotnet-skills";
        subdir = "plugins";
      };

      kiro-skills = {
        input = "kiro-skills";
        idPrefix = "kiro-skills";
        subdir = "skills";
      };

      critique = {
        input = "gemini-cli";
        idPrefix = "critique";
        subdir = "tools/gemini-cli-bot/.gemini/skills";
      };

      ecc = {
        input = "ecc";
        subdir = "skills";
        idPrefix = "ecc";
      };

      openclaw-github = {
        input = "openclaw";
        idPrefix = "openclaw-github";
        subdir = "skills";
      };

      svelte5-best-practices = {
        input = "autoskills";
        idPrefix = "svelte5-best-practices";
        subdir = "packages/autoskills/skills-registry";
      };

      terraform-module-library = {
        input = "wshobson-agents";
        idPrefix = "terraform-module-library";
        subdir = "plugins/cloud-infrastructure/skills";
      };

      terraform-specialist = {
        input = "cc-templates";
        idPrefix = "terraform-specialist";
        subdir = "cli-tool/components/skills/development";
      };

      google-cloud = {
        input = "google-skills";
        idPrefix = "google-cloud";
        subdir = "skills/cloud";
      };

      dot-skills = {
        input = "dot-skills";
        idPrefix = "dot-skills";
        subdir = "skills/.experimental";
      };

      genshijin = {
        input = "genshijin";
        idPrefix = "genshijin";
        subdir = "skills";
      };

      hashicorp-agent-skills = {
        input = "hashicorp-agent-skills";
        idPrefix = "hashicorp-agent-skills";
        subdir = "plugins/terraform/skills";
      };

      i-have-adhd = {
        input = "i-have-adhd";
        idPrefix = "i-have-adhd";
        subdir = "skills";
      };

      kaynetik-skills = {
        input = "kaynetik-skills";
        idPrefix = "kaynetik-skills";
      };

      natural-japanese = {
        input = "natural-japanese";
        idPrefix = "natural-japanese";
        subdir = "skills";
      };

      yomiyasu = {
        input = "yomiyasu";
        idPrefix = "yomiyasu";
        subdir = "skills";
      };

      openai-skills = {
        input = "openai-skills";
        idPrefix = "openai-skills";
        subdir = "skills/.curated";
      };

      spring-boot-skills = {
        input = "spring-boot-skills";
        idPrefix = "spring-boot-skills";
        subdir = "skills/spring-boot-4";
      };

      terminal-browser = {
        input = "terminal-browser";
        idPrefix = "terminal-browser";
        subdir = "skill";
      };

      superpowers = {
        input = "superpowers";
        idPrefix = "superpowers";
        subdir = "skills";
      };

      wshobson-agents = {
        input = "wshobson-agents";
        idPrefix = "wshobson-agents";
        subdir = "plugins/shell-scripting/skills";
      };
    };

    skills.enable = [
      "anthropic-skills/frontend-design"
      "openai-skills/gh-fix-ci"
      "kaynetik-skills/ultimate-nixos"
    ];

    targets.opencode.enable = true;
  };
}
