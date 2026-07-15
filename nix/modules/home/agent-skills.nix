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
    };

    skills.enable = [
      "genshijin"
      "natural-japanese"
      "ultimate-nixos"
    ];

    targets.opencode.enable = true;
  };
}
