{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.minecraft;

  customProfiles = lib.filterAttrs (_: profile: profile.type == "custom") cfg.profiles;

  builtinProfiles = lib.filterAttrs (_: profile: profile.type != "custom") cfg.profiles;

  builtinTypeCounts = lib.foldl' (
    counts: profile: counts // { ${profile.type} = (counts.${profile.type} or 0) + 1; }
  ) { } (lib.attrValues builtinProfiles);

  minecraftDir = ../../../minecraft;

  installers = import ../../../minecraft/installers.nix;

  loaders = import ../../../minecraft/loaders.nix;

  findPwTomlFiles =
    dir:
    lib.flatten (
      lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
        in
        if type == "directory" then
          findPwTomlFiles path
        else if type == "regular" && lib.hasSuffix ".pw.toml" name then
          [ path ]
        else
          [ ]
      ) (builtins.readDir dir)
    );

  readPwToml = path: builtins.fromTOML (builtins.readFile path);

  fetchPwToml =
    path:
    let
      pw = readPwToml path;
      hashFormat = pw.download."hash-format";
      hashAlgo =
        {
          sha256 = "sha256";
          sha512 = "sha512";
        }
        .${hashFormat} or (throw "${toString path}: unsupported download hash-format '${hashFormat}'");
    in
    pkgs.fetchurl {
      name = pw.filename;
      url = pw.download.url;
      hash = builtins.convertHash {
        hash = pw.download.hash;
        inherit hashAlgo;
        toHashFormat = "sri";
      };
    };

  profilePacks = lib.mapAttrs (
    name: _:
    let
      root = minecraftDir + "/${name}";
    in
    map (
      path:
      let
        relative = lib.removePrefix "${toString root}/" (toString path);
        pw = readPwToml path;
      in
      {
        subdir = builtins.head (lib.splitString "/" relative);
        inherit (pw) filename;
        file = fetchPwToml path;
      }
    ) (findPwTomlFiles root)
  ) customProfiles;

  homeRelative =
    path:
    if lib.hasPrefix "${config.home.homeDirectory}/" path then
      lib.removePrefix "${config.home.homeDirectory}/" path
    else
      throw "minecraft: ${path} is outside the home directory and cannot be managed with home.file";

  profileFiles = lib.concatMapAttrs (
    name: entries:
    lib.listToAttrs (
      map (entry: {
        name = "${homeRelative cfg.profiles.${name}.dir}/${entry.subdir}/${entry.filename}";
        value.source = entry.file;
      }) entries
    )
  ) profilePacks;

  profileLoaderVersion =
    name: profile:
    let
      version =
        if profile.loaderVersion != null then
          profile.loaderVersion
        else
          loaders.${profile.loader}.${profile.mcVersion} or null;
    in
    if version != null then
      version
    else
      throw "minecraft.profiles.${name}.loaderVersion is not set and minecraft/loaders.nix has no ${profile.loader} entry for ${profile.mcVersion}";

  profileVersionId =
    name: profile:
    if profile.loader == "vanilla" then
      profile.mcVersion
    else
      {
        fabric = "fabric-loader-${profileLoaderVersion name profile}-${profile.mcVersion}";
        quilt = "quilt-loader-${profileLoaderVersion name profile}-${profile.mcVersion}";
        neoforge = "neoforge-${profileLoaderVersion name profile}";
        forge = "${profile.mcVersion}-forge-${profileLoaderVersion name profile}";
      }
      .${profile.loader};

  loaderInstalls = lib.unique (
    lib.mapAttrsToList (name: profile: {
      inherit (profile) loader mcVersion;
      loaderVersion = profileLoaderVersion name profile;
    }) (lib.filterAttrs (_: profile: profile.loader != "vanilla") customProfiles)
  );

  usedLoaders = lib.unique (map (install: install.loader) loaderInstalls);

  installerEntry =
    install:
    if install.loader == "neoforge" || install.loader == "forge" then
      installers.${install.loader}.${install.mcVersion}.${install.loaderVersion}
        or (throw "minecraft: no ${install.loader} installer for Minecraft ${install.mcVersion} with loader ${install.loaderVersion}; run scripts/steps/050-update-minecraft.sh")
    else
      installers.${install.loader}
        or (throw "minecraft: no ${install.loader} installer; run scripts/steps/050-update-minecraft.sh");

  installerJar = install: pkgs.fetchurl { inherit (installerEntry install) name url hash; };

  loaderSupport = {
    fabric = {
      function = ''
        install_fabric() {
          local installer="$1"
          local mcVersion="$2"
          local loaderVersion="$3"

          java -jar "$installer" client \
            -dir "$baseDir" \
            -mcversion "$mcVersion" \
            -loader "$loaderVersion" \
            -noprofile
        }
      '';
      writesLauncherProfiles = false;
      command =
        install:
        "install_fabric ${installerJar install} ${lib.escapeShellArg install.mcVersion} ${lib.escapeShellArg install.loaderVersion}";
    };

    quilt = {
      function = ''
        install_quilt() {
          local installer="$1"
          local mcVersion="$2"
          local loaderVersion="$3"

          java -jar "$installer" install client \
            "$mcVersion" \
            "$loaderVersion" \
            --install-dir="$baseDir" \
            --no-profile
        }
      '';
      writesLauncherProfiles = false;
      command =
        install:
        "install_quilt ${installerJar install} ${lib.escapeShellArg install.mcVersion} ${lib.escapeShellArg install.loaderVersion}";
    };

    neoforge = {
      function = ''
        install_neoforge() {
          local installer="$1"

          if [[ ! -f "$launcherProfiles" ]]; then
            echo '{}' > "$launcherProfiles"
          fi

          java -jar "$installer" --install-client "$baseDir"
        }
      '';
      writesLauncherProfiles = true;
      command = install: "install_neoforge ${installerJar install}";
    };

    forge = {
      function = ''
        install_forge() {
          local installer="$1"
          local microsoftStoreProfiles="$baseDir/launcher_profiles_microsoft_store.json"

          if [[ ! -f "$launcherProfiles" && ! -f "$microsoftStoreProfiles" ]]; then
            echo '{}' > "$launcherProfiles"
          fi

          java -jar "$installer" --installClient "$baseDir"
        }
      '';
      writesLauncherProfiles = true;
      command = install: "install_forge ${installerJar install}";
    };
  };

  loaderFunctions = lib.concatMapStringsSep "\n" (
    loader: loaderSupport.${loader}.function
  ) usedLoaders;

  loaderCalls = lib.concatMapStringsSep "\n" (
    install:
    let
      support = loaderSupport.${install.loader};
      installerCommand = support.command install;
    in
    if support.writesLauncherProfiles then
      ''
        if launcherRunning; then
          echo "warning: Minecraft launcher is running; skipping the ${install.loader} installer" >&2
        else
          ${installerCommand}
        fi
      ''
    else
      installerCommand
  ) loaderInstalls;

  pgrepPath =
    if pkgs.stdenv.hostPlatform.isDarwin then "/usr/bin/pgrep" else "${pkgs.procps}/bin/pgrep";

  minecraft-provision = pkgs.writeShellApplication {
    name = "minecraft-provision";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.jdk
      pkgs.jq
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.procps;

    text = ''
      baseDir=${lib.escapeShellArg cfg.baseDir}
      launcherProfiles="$baseDir/launcher_profiles.json"
      pgrepBin=${pgrepPath}

      launcherRunning() {
        if [[ ! -x "$pgrepBin" ]]; then
          echo "warning: pgrep is not available; assuming the Minecraft launcher may be running" >&2
          return 0
        fi
        "$pgrepBin" -f "Minecraft.app/Contents/MacOS/launcher" >/dev/null 2>&1 && return 0
        "$pgrepBin" -f "launcher.bundle/Contents/MacOS/launcher" >/dev/null 2>&1 && return 0
        "$pgrepBin" -f '^[^ ]*[m]inecraft-launcher' >/dev/null 2>&1 && return 0
        return 1
      }

      ${loaderFunctions}

      ${loaderCalls}

      if launcherRunning; then
        echo "warning: Minecraft launcher is running; skipping launcher_profiles.json update" >&2
        exit 0
      fi

      if [[ ! -f "$launcherProfiles" ]]; then
        echo "warning: $launcherProfiles does not exist; skipping profile registration" >&2
        exit 0
      fi

      if ! jq -e . "$launcherProfiles" >/dev/null 2>&1; then
        echo "warning: $launcherProfiles is not valid JSON; leaving it unchanged" >&2
        exit 0
      fi

      now="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
      originalHash="$(sha256sum "$launcherProfiles" | cut -d' ' -f1)"
      work=""
      next=""
      cleanup() {
        [[ -z "$work" ]] || rm -f "$work"
        [[ -z "$next" ]] || rm -f "$next"
        return 0
      }
      trap cleanup EXIT
      work="$(mktemp "$baseDir/launcher_profiles.json.XXXXXX")"
      cp -p "$launcherProfiles" "$work"

      merge_profile() {
        local id="$1"
        local name="$2"
        local dir="$3"
        local versionId="$4"
        local icon="$5"

        mkdir -p "$dir"

        next="$(mktemp "$baseDir/launcher_profiles.json.XXXXXX")"
        if ! jq -e -s \
          --arg id "$id" \
          --arg name "$name" \
          --arg dir "$dir" \
          --arg versionId "$versionId" \
          --arg icon "$icon" \
          --arg now "$now" \
          '
            if length != 1 then empty else .[0] end |
            .profiles = (.profiles // {}) |
            .profiles[$id] = ((.profiles[$id] // {}) + {
              name: $name,
              type: "custom",
              created: (.profiles[$id].created // $now),
              lastUsed: (.profiles[$id].lastUsed // $now),
              lastVersionId: $versionId,
              gameDir: $dir
            }) |
            (if $icon == "" then . else .profiles[$id].icon = $icon end) |
            .version = (.version // 6)
          ' \
          "$work" > "$next" || [[ ! -s "$next" ]] || ! jq -e . "$next" >/dev/null 2>&1; then
          rm -f "$next"
          next=""
          echo "warning: failed to update $launcherProfiles; leaving it unchanged" >&2
          return 0
        fi
        mv -f "$next" "$work"
        next=""
      }

      merge_builtin() {
        local type="$1"
        local dir="$2"
        local count

        count="$(jq --arg type "$type" '[.profiles // {} | to_entries[] | select(.value.type == $type)] | length' "$work" 2>/dev/null)" || return 0
        if [[ "$count" != "1" ]]; then
          echo "warning: found $count launcher profiles of type $type; skipping its game directory" >&2
          return 0
        fi

        mkdir -p "$dir"

        next="$(mktemp "$baseDir/launcher_profiles.json.XXXXXX")"
        if ! jq -e \
          --arg type "$type" \
          --arg dir "$dir" \
          '
            ([.profiles // {} | to_entries[] | select(.value.type == $type)] | first) as $entry |
            .profiles[$entry.key].gameDir = $dir |
            .version = (.version // 6)
          ' \
          "$work" > "$next" || [[ ! -s "$next" ]] || ! jq -e . "$next" >/dev/null 2>&1; then
          rm -f "$next"
          next=""
          echo "warning: failed to update $launcherProfiles; leaving it unchanged" >&2
          return 0
        fi
        mv -f "$next" "$work"
        next=""
      }

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: profile:
          "merge_profile ${lib.escapeShellArg name} ${lib.escapeShellArg name} ${lib.escapeShellArg profile.dir} ${lib.escapeShellArg (profileVersionId name profile)} ${
            lib.escapeShellArg (if profile.icon == null then "" else profile.icon)
          }"
        ) customProfiles
      )}

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _: profile: "merge_builtin ${lib.escapeShellArg profile.type} ${lib.escapeShellArg profile.dir}"
        ) builtinProfiles
      )}

      newHash="$(sha256sum "$work" | cut -d' ' -f1)"
      if [[ "$newHash" == "$originalHash" ]]; then
        exit 0
      fi

      if launcherRunning; then
        echo "warning: the Minecraft launcher started during the update; leaving $launcherProfiles unchanged" >&2
        exit 0
      fi

      if [[ "$(sha256sum "$launcherProfiles" | cut -d' ' -f1)" != "$originalHash" ]]; then
        echo "warning: $launcherProfiles changed during the update; leaving it unchanged" >&2
        exit 0
      fi

      cp -f "$launcherProfiles" "$launcherProfiles.bak"
      chmod --reference="$launcherProfiles" "$work" 2>/dev/null || chmod 644 "$work"
      mv -f "$work" "$launcherProfiles"
    '';
  };
in
{
  options.minecraft = {
    baseDir = lib.mkOption {
      type = lib.types.str;
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options.dir = lib.mkOption {
              type = lib.types.str;
              default = "${cfg.baseDir}/profiles/${name}";
            };

            options.type = lib.mkOption {
              type = lib.types.enum [
                "custom"
                "latest-release"
                "latest-snapshot"
              ];
              default = "custom";
            };

            options.icon = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            options.mcVersion = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            options.loaderVersion = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            options.loader = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "vanilla"
                  "fabric"
                  "quilt"
                  "neoforge"
                  "forge"
                ]
              );
              default = null;
            };
          }
        )
      );
      default = { };
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.all (profile: profile.loader != null && profile.mcVersion != null) (
          lib.attrValues customProfiles
        );
        message = "minecraft.profiles: custom profiles require loader and mcVersion";
      }
      {
        assertion = lib.all (
          profile: profile.loader == null && profile.mcVersion == null && profile.loaderVersion == null
        ) (lib.attrValues builtinProfiles);
        message = "minecraft.profiles: built-in profiles must not set loader, mcVersion or loaderVersion";
      }
      {
        assertion = lib.all (profile: profile.icon == null) (lib.attrValues builtinProfiles);
        message = "minecraft.profiles: built-in profiles cannot set icon";
      }
      {
        assertion = lib.all (count: count <= 1) (lib.attrValues builtinTypeCounts);
        message = "minecraft.profiles: each built-in profile type can be configured at most once";
      }
    ];

    home.file = profileFiles;

    home.activation.minecraftProvision = lib.mkIf (cfg.profiles != { }) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${minecraft-provision}/bin/minecraft-provision
      ''
    );
  };
}
