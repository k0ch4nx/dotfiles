{ config, pkgs, ... }:

let
  yabai = "${config.services.yabai.package}/bin/yabai";
in
{
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
  };

  system.activationScripts.extraActivation.text = ''
    (
      tccDatabase="/Library/Application Support/com.apple.TCC/TCC.db"
      csreqFile="$(/usr/bin/mktemp /var/tmp/yabai.csreq.XXXXXX)"

      trap '/bin/rm -f "$csreqFile"' EXIT HUP INT TERM

      if [[ ! -w "$tccDatabase" ]]; then
        exit 1
      fi

      codesignOutput="$(/usr/bin/codesign -d -r- "${yabai}" 2>&1)"
      requirement="$(/usr/bin/printf '%s\n' "$codesignOutput" | /usr/bin/sed -n 's/^# designated => //p')"

      if [[ -z "$requirement" ]]; then
        exit 1
      fi

      /usr/bin/csreq -r="$requirement" -b "$csreqFile"
      csreqHex="$(/usr/bin/xxd -p "$csreqFile" | /usr/bin/tr -d '\n')"

      ${pkgs.sqlite}/bin/sqlite3 "$tccDatabase" <<SQL
    .bail on
    .timeout 5000
    BEGIN IMMEDIATE;
    INSERT OR REPLACE INTO access (
      service,
      client,
      client_type,
      auth_value,
      auth_reason,
      auth_version,
      csreq,
      flags
    ) VALUES
      ('kTCCServiceAccessibility', '${yabai}', 1, 2, 4, 1, X'$csreqHex', 0),
      ('kTCCServiceScreenCapture', '${yabai}', 1, 2, 4, 1, X'$csreqHex', 0);
    DELETE FROM access
      WHERE client_type = 1
        AND client != '${yabai}'
        AND client GLOB '/nix/store/*-yabai-*/bin/yabai'
        AND service IN (
          'kTCCServiceAccessibility',
          'kTCCServiceScreenCapture'
        );
    COMMIT;
    SQL
    )
  '';
}
