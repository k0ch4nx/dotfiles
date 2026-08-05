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

      mattpocock-skills = {
        input = "mattpocock-skills";
        subdir = "skills";
        filter.nameRegex = "^(engineering|productivity)/.+";
      };

      cloudflare-skills = {
        input = "cloudflare-skills";
        subdir = "skills";
      };

      critique = {
        input = "gemini-cli";
        subdir = "tools/gemini-cli-bot/.gemini/skills";
        filter.nameRegex = "^critique$";
      };

      ecc = {
        input = "ecc";
        subdir = "skills";
        idPrefix = "ecc";
      };

      openclaw-github = {
        input = "openclaw";
        subdir = "skills";
        filter.nameRegex = "^github$";
      };

      svelte5-best-practices = {
        input = "autoskills";
        subdir = "packages/autoskills/skills-registry";
        filter.nameRegex = "^svelte5-best-practices$";
      };

      terraform-module-library = {
        input = "wshobson-agents";
        subdir = "plugins/cloud-infrastructure/skills";
        filter.nameRegex = "^terraform-module-library$";
      };

      terraform-specialist = {
        input = "cc-templates";
        subdir = "cli-tool/components/skills/development";
        filter.nameRegex = "^terraform-specialist$";
      };

      google-cloud = {
        input = "google-skills";
        subdir = "skills/cloud";
        filter.nameRegex = "^(gcloud|cloud-run-basics|google-cloud-networking-observability|google-cloud-global-frontend-configuration|gke-networking)$";
      };

      dot-skills = {
        input = "dot-skills";
        subdir = "skills/.experimental";
        filter.nameRegex = "shell";
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
        filter.nameRegex = "bash-defensive-patterns";
      };
    };

    skills.enableAll = true;

    targets.opencode.enable = true;
  };
}
