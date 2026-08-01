{
  config,
  lib,
  pkgs,
  ...
}:

let
  opencodeDir = "${config.dotfiles.path}/nix/home/k0ch4nx/files/opencode";
in
{
  home.file = {
    ".config/opencode/opencode.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${opencodeDir}/opencode.json";
      force = true;
    };
    ".config/opencode/cli.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${opencodeDir}/cli.json";
      force = true;
    };
  };

  home.activation.updateOpenCodeCacheHitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      configDir="${config.home.homeDirectory}/.config/opencode"
      target="$configDir/cache-hit.json"

      if [ -n "$DRY_RUN_CMD" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf '%s\n' "would refresh $target"
        exit 0
      fi

      responseFile="$(${pkgs.coreutils}/bin/mktemp "$configDir/.cache-hit-response.XXXXXX")" || exit 0
      temporaryFile="$(${pkgs.coreutils}/bin/mktemp "$configDir/.cache-hit.json.XXXXXX")" || {
        ${pkgs.coreutils}/bin/rm -f "$responseFile"
        exit 0
      }
      cleanup() {
        ${pkgs.coreutils}/bin/rm -f "$responseFile" "$temporaryFile"
      }
      trap cleanup EXIT

      ${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 10 \
        https://api.frankfurter.dev/v2/rate/USD/JPY \
        > "$responseFile" || exit 0

      rate="$(${pkgs.jq}/bin/jq --exit-status --raw-output \
        '.rate | select(type == "number" and . > 0)' \
        < "$responseFile")" || exit 0

      ${pkgs.jq}/bin/jq --null-input --argjson rate "$rate" \
        '{currency: "JPY", costUnit: "USD", rate: $rate,
          display: {lang: "en", panelBorder: true, showSpeed: true, speedUnit: "tps"}}' \
        > "$temporaryFile" || exit 0

      ${pkgs.coreutils}/bin/rm -f "$responseFile"
      ${pkgs.coreutils}/bin/mv -f "$temporaryFile" "$target"
      trap - EXIT
    )
  '';
}
