{ inputs, ... }:

{
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  programs.agent-skills = {
    enable = true;

    sources = {
      genshijin = {
        input = "genshijin";
        subdir = "skills";
      };

      natural-japanese = {
        input = "natural-japanese";
        subdir = "skills";
      };

      kaynetik-skills = {
        input = "kaynetik-skills";
        filter.nameRegex = "ultimate-nixos";
      };

      cloudflare-skills = {
        input = "cloudflare-skills";
        subdir = "skills";
      };

      superpowers = {
        input = "superpowers";
        subdir = "skills";
      };

      anthropic-skills = {
        input = "anthropic-skills";
        subdir = "skills";
        filter.nameRegex = "frontend-design";
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
      "genshijin"
      "natural-japanese"
      "receiving-code-review"
      "requesting-code-review"
      "sandbox-sdk"
      "subagent-driven-development"
      "systematic-debugging"
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
