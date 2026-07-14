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
    };

    skills.enable = [
      "genshijin"
      "natural-japanese"
    ];

    targets.opencode.enable = true;
  };
}
