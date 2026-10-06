{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.rift.signedCopy;

  home = config.home.homeDirectory;
  signedDir = "${home}/.local/libexec/rift";
  stateDir = "${home}/.local/state/rift-signed";
  dst = "${signedDir}/rift";
  markerPath = "${stateDir}/marker.json";
  lockFile = "${stateDir}/.rift-sign.lock";
  pemPath = config.age.secrets.rift-codesign.path;

  identifier = "rift";
  policyVersion = "1";
  sourcePackage = "${pkgs.rift-wm}";
  signerPackage = "${pkgs.rcodesign}";

  riftLabel = config.launchd.agents.rift.config.Label;

  restartRift = ''
    userId="$(id -u)"
    if launchctl print "gui/$userId/${riftLabel}" >/dev/null 2>&1; then
      launchctl kickstart -k "gui/$userId/${riftLabel}"
    fi
  '';

  launcher = pkgs.writeShellScript "rift-signed-launcher" ''
    signed="${dst}"

    if [ -x "$signed" ]; then
      exec "$signed"
    fi

    attempts=0
    while [ "$attempts" -lt 300 ]; do
      /bin/sleep 1
      if [ -x "$signed" ]; then
        exec "$signed"
      fi
      attempts=$((attempts + 1))
    done

    echo "rift: signed executable unavailable; awaiting activation" >&2
    exit 0
  '';

  riftSign = ''
    if [[ -v DRY_RUN ]]; then
      echo "Would sign rift and reconcile the launchd service"
    else
      jobRef="gui/$(/usr/bin/id -u)/${riftLabel}"

      log() {
        echo "rift-sign: $*" >&2
      }

      markerField() {
        "${pkgs.jq}/bin/jq" -r --arg key "$1" 'if has($key) then .[$key] else "" end' "${markerPath}" 2>/dev/null || true
      }

      setPendingRestart() {
        local value="$1"
        local tmp
        [ -f "${markerPath}" ] || return 0
        tmp="$(/usr/bin/mktemp "${stateDir}/.marker.XXXXXX")" || return 1
        if "${pkgs.jq}/bin/jq" --argjson value "$value" '.pendingRestart = $value' "${markerPath}" > "$tmp" \
          && /bin/chmod 600 "$tmp" \
          && /bin/mv -f "$tmp" "${markerPath}"; then
          return 0
        fi
        /bin/rm -f "$tmp"
        return 1
      }

      jobRegistered() {
        /bin/launchctl print "$jobRef" >/dev/null 2>&1
      }

      kickstartRift() {
        if ! jobRegistered; then
          log "launchd job $jobRef is not registered yet; it will pick up the signed copy when loaded"
          return 2
        fi
        if run /bin/launchctl kickstart -k "$jobRef"; then
          return 0
        fi
        log "warning: failed to kickstart $jobRef; pendingRestart stays set and will be retried"
        return 1
      }

      fileSha256() {
        /usr/bin/shasum -a 256 "$1" | /usr/bin/awk '{print $1}'
      }

      certificateSha() {
        "${pkgs.openssl}/bin/openssl" x509 -in "$pem" -outform DER 2>/dev/null \
          | /usr/bin/shasum -a "$1" | /usr/bin/awk '{print $1}'
      }

      verifySigned() {
        local requirement
        local dr
        local expectedIdentifier
        local expectedIdentifierQuoted
        local expectedRoot
        requirement="=identifier \"${identifier}\" and certificate root = H\"$certSha1\""
        /usr/bin/codesign --verify --strict --test-requirement="$requirement" "$1" >/dev/null 2>&1 || return 1
        dr="$(/usr/bin/codesign -d -r- "$1" 2>&1)" || return 1
        case "$dr" in
          *cdhash*) return 1 ;;
        esac
        expectedIdentifier="identifier ${identifier}"
        expectedIdentifierQuoted="identifier \"${identifier}\""
        expectedRoot="certificate root = H\"$certSha1\""
        case "$dr" in
          *"$expectedIdentifier"* | *"$expectedIdentifierQuoted"*) : ;;
          *) return 1 ;;
        esac
        case "$dr" in
          *"$expectedRoot"*) return 0 ;;
          *) return 1 ;;
        esac
      }

      inspectFileDeps() {
        local f="$1"
        local out first deps rc store
        [ -f "$f" ] || return 1
        if ! /usr/bin/file -b "$f" | /usr/bin/grep -q 'Mach-O'; then
          log "warning: $f is not a Mach-O file"
          return 1
        fi
        if ! out="$(/usr/bin/otool -L "$f" 2>/dev/null)"; then
          log "warning: cannot read the load commands of $f"
          return 1
        fi
        if ! first="$(printf '%s\n' "$out" | /usr/bin/head -n 1)"; then
          log "warning: cannot parse the otool output for $f"
          return 1
        fi
        case "$first" in
          *:) ;;
          *)
            log "warning: unexpected otool output for $f"
            return 1
            ;;
        esac
        if ! deps="$(printf '%s\n' "$out" | /usr/bin/tail -n +2 | /usr/bin/awk '{print $1}')"; then
          log "warning: cannot parse the load commands of $f"
          return 1
        fi
        rc=0
        printf '%s\n' "$deps" | /usr/bin/grep -q '^@' || rc=$?
        case "$rc" in
          0)
            log "warning: $f has unresolved dynamic dependencies"
            return 1
            ;;
          1) ;;
          *)
            log "warning: cannot search the dependencies of $f"
            return 1
            ;;
        esac
        rc=0
        store="$(printf '%s\n' "$deps" | /usr/bin/grep '^/nix/store/')" || rc=$?
        case "$rc" in
          0) printf '%s\n' "$store" ;;
          1) ;;
          *)
            log "warning: cannot filter the dependencies of $f"
            return 1
            ;;
        esac
        return 0
      }

      rootFileDeps() {
        local strict="$1"
        local f dep deps entry
        shift
        for f in "$@"; do
          [ -e "$f" ] || continue
          if ! deps="$(inspectFileDeps "$f")"; then
            if [ "$strict" = "strict" ]; then
              log "error: cannot protect the runtime dependencies of $f"
              return 1
            fi
            rootsIncomplete=1
            continue
          fi
          for dep in $deps; do
            entry="$(printf '%s' "$dep" | /usr/bin/sed -e 's|^/nix/store/||' -e 's|/.*$||')"
            if "${pkgs.nix}/bin/nix-store" \
              --add-root "${stateDir}/gcroots/$entry" --indirect \
              --realise "$dep" >/dev/null 2>&1; then
              continue
            fi
            if [ "$strict" = "strict" ]; then
              log "error: failed to add the gc root for $dep"
              return 1
            fi
            log "warning: failed to add the gc root for $dep (non-fatal)"
            rootsIncomplete=1
          done
        done
        return 0
      }

      pruneRoots() {
        local wanted="|"
        local f dep deps entry name
        for f in "$@"; do
          [ -e "$f" ] || continue
          if ! deps="$(inspectFileDeps "$f")"; then
            log "warning: cannot inspect $f; skipping gc root pruning (non-fatal)"
            return 0
          fi
          for dep in $deps; do
            entry="$(printf '%s' "$dep" | /usr/bin/sed -e 's|^/nix/store/||' -e 's|/.*$||')"
            wanted="$wanted$entry|"
          done
        done
        for entry in "${stateDir}"/gcroots/*; do
          [ -e "$entry" ] || continue
          name="$(/usr/bin/basename "$entry")"
          case "$wanted" in
            *"|$name|"*) ;;
            *) /bin/rm -f "$entry" ;;
          esac
        done
        return 0
      }

      resignAttemptFailed() {
        /bin/rm -f "$candidate"
        if [ -e "$dst" ]; then
          log "warning: $1; keeping the existing signed copy"
          return 0
        fi
        log "error: $1; no signed copy exists yet, rift will wait for the next activation"
        return 1
      }

      acquireLock() {
        if [ ! -d "${stateDir}" ]; then
          /bin/mkdir -p "${stateDir}" || {
            log "warning: cannot create ${stateDir}; skipping signing (non-fatal)"
            return 1
          }
        fi
        exec 9>"${lockFile}" || {
          log "warning: cannot open ${lockFile}; skipping signing (non-fatal)"
          return 1
        }
        if ! "${pkgs.flock}/bin/flock" -n 9; then
          log "another rift signing run holds the lock; skipping (non-fatal)"
          exec 9>&-
          return 1
        fi
        printf '%s\n' "$$" >&9 || true
        return 0
      }

      releaseLock() {
        exec 9>&- || true
      }

      signRiftInner() {
        dst="${dst}"
        pem="${pemPath}"
        candidate=""
        rootsIncomplete=""

        if [ ! -r "$pem" ]; then
          resignAttemptFailed "codesign PEM is not readable at $pem" && return 0
          return 1
        fi

        if ! "${pkgs.openssl}/bin/openssl" x509 -in "$pem" -noout >/dev/null 2>&1; then
          resignAttemptFailed "the PEM at $pem does not contain a readable x509 certificate" && return 0
          return 1
        fi

        if ! certSha1="$(certificateSha 1)"; then
          resignAttemptFailed "could not compute the certificate SHA-1 from $pem" && return 0
          return 1
        fi
        if ! certSha256="$(certificateSha 256)"; then
          resignAttemptFailed "could not compute the certificate SHA-256 from $pem" && return 0
          return 1
        fi
        if [ -z "$certSha1" ] || [ -z "$certSha256" ]; then
          resignAttemptFailed "empty certificate fingerprint computed from $pem" && return 0
          return 1
        fi

        currentSource="${sourcePackage}"
        currentSigner="${signerPackage}"

        markerSource=""
        markerCert=""
        markerSigner=""
        markerPolicy=""
        markerIdentifier=""
        markerHash=""
        markerPending=""
        if [ -f "${markerPath}" ]; then
          markerSource="$(markerField source)"
          markerCert="$(markerField certDerSha256)"
          markerSigner="$(markerField signerStorePath)"
          markerPolicy="$(markerField policyVersion)"
          markerIdentifier="$(markerField identifier)"
          markerHash="$(markerField signedSha256)"
          markerPending="$(markerField pendingRestart)"
          if [ -n "$markerCert" ] && [ "$markerCert" != "$certSha256" ]; then
            log "warning: the signing certificate changed since the installed copy was signed; macOS may require re-granting Accessibility"
          fi
        fi

        if [ -f "${markerPath}" ] \
          && [ "$markerSource" = "$currentSource" ] \
          && [ "$markerCert" = "$certSha256" ] \
          && [ "$markerSigner" = "$currentSigner" ] \
          && [ "$markerPolicy" = "${policyVersion}" ] \
          && [ "$markerIdentifier" = "${identifier}" ] \
          && [ -f "$dst" ] && [ ! -L "$dst" ] && [ -x "$dst" ]; then
          dstSha="$(fileSha256 "$dst")"
          if [ -n "$markerHash" ] && [ "$dstSha" = "$markerHash" ] && verifySigned "$dst"; then
            rootFileDeps soft "$dst" "${signedDir}/rift.prev"
            if [ -z "$rootsIncomplete" ]; then
              pruneRoots "$dst" "${signedDir}/rift.prev"
            fi
            if [ "$markerPending" = "true" ]; then
              if kickstartRift; then
                setPendingRestart false || log "warning: failed to clear pendingRestart (non-fatal)"
              fi
            fi
            return 0
          fi
        fi

        candidate=""
        if ! candidate="$(/usr/bin/mktemp "${signedDir}/.rift.new.XXXXXX")"; then
          resignAttemptFailed "failed to create a temporary candidate in ${signedDir}" && return 0
          return 1
        fi

        if ! /bin/chmod 700 "$candidate"; then
          resignAttemptFailed "failed to set the candidate mode to 700" && return 0
          return 1
        fi

        if ! /bin/cp "${pkgs.rift-wm}/bin/rift" "$candidate"; then
          resignAttemptFailed "failed to copy ${pkgs.rift-wm}/bin/rift" && return 0
          return 1
        fi

        if ! "${pkgs.rcodesign}/bin/rcodesign" sign \
          --pem-file "$pem" \
          --binary-identifier "${identifier}" \
          --timestamp-url none \
          --config-file /dev/null \
          "$candidate"; then
          resignAttemptFailed "rcodesign sign failed" && return 0
          return 1
        fi

        if ! verifySigned "$candidate"; then
          resignAttemptFailed "signature verification of the candidate failed" && return 0
          return 1
        fi

        if ! rootFileDeps strict "$dst" "${pkgs.rift-wm}/bin/rift"; then
          resignAttemptFailed "failed to protect the runtime dependencies of the signed copy" && return 0
          return 1
        fi
        rootFileDeps soft "${signedDir}/rift.prev"

        if [ -e "$dst" ]; then
          if /bin/cp "$dst" "${signedDir}/.rift.prev.new" \
            && /bin/chmod 700 "${signedDir}/.rift.prev.new" \
            && /bin/mv -f "${signedDir}/.rift.prev.new" "${signedDir}/rift.prev"; then
            :
          else
            /bin/rm -f "${signedDir}/.rift.prev.new"
            resignAttemptFailed "failed to preserve the previous signed copy; not publishing" && return 0
            return 1
          fi
        fi

        if ! /bin/mv -f "$candidate" "$dst"; then
          resignAttemptFailed "failed to publish the signed copy" && return 0
          return 1
        fi

        rootFileDeps soft "$dst" "${signedDir}/rift.prev"
        if [ -z "$rootsIncomplete" ]; then
          pruneRoots "$dst" "${signedDir}/rift.prev"
        fi

        signedHash="$(fileSha256 "$dst")"
        if [ -n "$signedHash" ]; then
          markerTmp=""
          if markerTmp="$(/usr/bin/mktemp "${stateDir}/.marker.XXXXXX")" \
            && "${pkgs.jq}/bin/jq" -n \
              --arg source "$currentSource" \
              --arg certDerSha256 "$certSha256" \
              --arg signerStorePath "$currentSigner" \
              --arg policyVersion "${policyVersion}" \
              --arg identifier "${identifier}" \
              --arg signedSha256 "$signedHash" \
              '{source: $source, certDerSha256: $certDerSha256, signerStorePath: $signerStorePath, policyVersion: $policyVersion, identifier: $identifier, signedSha256: $signedSha256, pendingRestart: true}' > "$markerTmp" \
            && /bin/chmod 600 "$markerTmp" \
            && /bin/mv -f "$markerTmp" "${markerPath}"; then
            :
          else
            [ -n "$markerTmp" ] && /bin/rm -f "$markerTmp"
            log "warning: failed to update the marker (non-fatal)"
          fi
        else
          log "warning: could not determine the signed hash; leaving the marker unchanged (non-fatal)"
        fi

        if kickstartRift; then
          setPendingRestart false || log "warning: failed to clear pendingRestart (non-fatal)"
        fi

        return 0
      }

      signRiftAndReconcile() {
        local rc
        if ! acquireLock; then
          return 0
        fi
        if signRiftInner; then
          rc=0
        else
          rc=1
        fi
        releaseLock
        return "$rc"
      }

      if signRiftAndReconcile; then
        :
      else
        exit 1
      fi
    fi
  '';
in

{
  options.rift.signedCopy.enable = lib.mkEnableOption ''
    signing a stable copy of rift with a self-signed certificate and launching
    that copy from launchd instead of the store path
  '';

  config = {
    home.packages = [ pkgs.rift-wm ];

    launchd.agents.rift = {
      enable = true;
      config = lib.mkMerge [
        {
          ProgramArguments = [ "${pkgs.rift-wm}/bin/rift" ];
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          Nice = -20;
          ProcessType = "Interactive";
          EnvironmentVariables = {
            XDG_CONFIG_HOME =
              if config.xdg.enable then config.xdg.configHome else "${config.home.homeDirectory}/.config";
          };
          RunAtLoad = true;
        }
        (lib.mkIf cfg.enable {
          ProgramArguments = lib.mkForce [ "${launcher}" ];
        })
      ];
    };

    home.activation.riftPrepare = lib.mkIf cfg.enable (
      lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
        run ${pkgs.coreutils}/bin/install -d -m 700 "${signedDir}" "${stateDir}" "${stateDir}/gcroots"
      ''
    );

    home.activation.riftSign = lib.mkIf cfg.enable (
      lib.hm.dag.entryAfter [ "activateAgenixInteractively" ] riftSign
    );

    xdg.configFile."rift/config.toml" = lib.mkIf config.xdg.enable {
      source = ./files/rift/config.toml;
      onChange = restartRift;
    };
  };
}
