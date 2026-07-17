{ pkgs }:
{
  name,
  runtimeInputs ? [ ],
  script,
}:

pkgs.writeShellApplication {
  inherit name;

  runtimeInputs =
    [
      pkgs.coreutils
      pkgs.git
    ]
    ++ runtimeInputs;

  text = ''
    ${builtins.readFile ./scripts/lib/dotfiles.sh}
    ${builtins.readFile script}
  '';
}
