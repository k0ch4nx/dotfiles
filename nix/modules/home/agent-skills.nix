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

    skills.enable = [
      "agents-sdk"
      "brainstorming"
      "cloudflare-email-service"
      "cloudflare-one-migrations"
      "cloudflare-one"
      "cloudflare"
      "dispatching-parallel-agents"
      "durable-objects"
      "executing-plans"
      "finishing-a-development-branch"
      "frontend-design"
      "gh-fix-ci"
      "genshijin"
      "i-have-adhd"
      "insecure-defaults"
      "natural-japanese"
      "receiving-code-review"
      "requesting-code-review"
      "sandbox-sdk"
      "subagent-driven-development"
      "systematic-debugging"
      "terraform-style-guide"
      "test-driven-development"
      "turnstile-spin"
      "ultimate-nixos"
      "using-git-worktrees"
      "using-superpowers"
      "verification-before-completion"
      "web-perf"
      "workers-best-practices"
      "wrangler"
      "writing-plans"
      "writing-skills"
    ];

    targets.codex.enable = true;
    targets.opencode.enable = true;
  };
}
