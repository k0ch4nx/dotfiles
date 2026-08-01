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
        /usr/bin/logger -t nix-darwin-tcc "TCC database not writable; skipping yabai TCC update"
        exit 0
      fi

      codesignOutput="$(/usr/bin/codesign -d -r- "${yabai}" 2>&1)"
      requirement="$(/usr/bin/printf '%s\n' "$codesignOutput" | /usr/bin/sed -n 's/^# designated => //p')"

      if [[ -z "$requirement" ]]; then
        /usr/bin/logger -t nix-darwin-tcc "no designated requirement for ${yabai}; skipping yabai TCC update"
        exit 0
      fi

      if ! /usr/bin/csreq -r="$requirement" -b "$csreqFile"; then
        /usr/bin/logger -t nix-darwin-tcc "csreq failed for ${yabai}; skipping yabai TCC update"
        exit 0
      fi

      csreqHex="$(/usr/bin/xxd -p "$csreqFile" | /usr/bin/tr -d '\n')"

      tableColumns="$(${pkgs.sqlite}/bin/sqlite3 "$tccDatabase" 'PRAGMA table_info(access);')"

      for column in service client client_type auth_value auth_reason auth_version csreq flags; do
        if ! /usr/bin/grep -q "^[0-9]*|$column|" <<<"$tableColumns"; then
          /usr/bin/logger -t nix-darwin-tcc "access table missing column $column; skipping yabai TCC update"
          exit 0
        fi
      done

      grantCount() {
        ${pkgs.sqlite}/bin/sqlite3 "$tccDatabase" <<SQL
    .bail on
    .timeout 5000
    SELECT COUNT(*) FROM access
    WHERE client = '${yabai}'
      AND service IN ('kTCCServiceAccessibility', 'kTCCServiceScreenCapture')
      AND auth_value = 2
      AND lower(hex(csreq)) = '$csreqHex';
    SQL
      }

      if [[ "$(grantCount)" == "2" ]]; then
        /usr/bin/logger -t nix-darwin-tcc "yabai TCC grants already match; no update needed"
        exit 0
      fi

      /bin/mkdir -p /var/db/nix-darwin/tcc-backups
      /bin/chmod 0700 /var/db/nix-darwin/tcc-backups
      backupFile="/var/db/nix-darwin/tcc-backups/tcc-$(/bin/date +%Y%m%d%H%M%S).db"

      if ! ${pkgs.sqlite}/bin/sqlite3 "$tccDatabase" ".backup '$backupFile'"; then
        /usr/bin/logger -t nix-darwin-tcc "TCC database backup failed; skipping yabai TCC update"
        exit 0
      fi

      ${pkgs.sqlite}/bin/sqlite3 "$tccDatabase" <<SQL || /usr/bin/logger -t nix-darwin-tcc "yabai TCC update failed"
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

      if [[ "$(grantCount)" == "2" ]]; then
        /usr/bin/logger -t nix-darwin-tcc "yabai TCC grants updated"
      fi
    )
  '';
}
