{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.minecraft;

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
  ) cfg.profiles;

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
    }) (lib.filterAttrs (_: profile: profile.loader != "vanilla") cfg.profiles)
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
      command = install: "install_forge ${installerJar install}";
    };
  };

  loaderFunctions = lib.concatMapStringsSep "\n" (
    loader: loaderSupport.${loader}.function
  ) usedLoaders;

  loaderCalls = lib.concatMapStringsSep "\n" (
    install: loaderSupport.${install.loader}.command install
  ) loaderInstalls;

  minecraft-provision = pkgs.writeShellApplication {
    name = "minecraft-provision";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.jdk
      pkgs.jq
    ];

    text = ''
      baseDir=${lib.escapeShellArg cfg.baseDir}
      launcherProfiles="$baseDir/launcher_profiles.json"

      launcherRunning=0
      if pgrep -x Minecraft >/dev/null 2>&1; then
        echo "warning: Minecraft launcher is running; skipping launcher_profiles.json update" >&2
        launcherRunning=1
      fi

      ${loaderFunctions}

      ${loaderCalls}

      if [[ "$launcherRunning" == 1 ]]; then
        exit 0
      fi

      if [[ ! -f "$launcherProfiles" ]]; then
        echo "warning: $launcherProfiles does not exist; skipping profile registration" >&2
        exit 0
      fi

      cp -f "$launcherProfiles" "$launcherProfiles.bak"

      now="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
      temporary="$(mktemp "$baseDir/launcher_profiles.json.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT

      merge_profile() {
        local id="$1"
        local name="$2"
        local dir="$3"
        local versionId="$4"

        mkdir -p "$dir"

        jq \
          --arg id "$id" \
          --arg name "$name" \
          --arg dir "$dir" \
          --arg versionId "$versionId" \
          --arg now "$now" \
          '
            .profiles = (.profiles // {}) |
            .profiles[$id] = ((.profiles[$id] // {}) + {
              name: $name,
              type: "custom",
              created: (.profiles[$id].created // $now),
              lastUsed: (.profiles[$id].lastUsed // $now),
              lastVersionId: $versionId,
              gameDir: $dir
            }) |
            .version = (.version // 6)
          ' \
          "$launcherProfiles" > "$temporary"

        mv -f "$temporary" "$launcherProfiles"
      }

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: profile:
          "merge_profile ${lib.escapeShellArg name} ${lib.escapeShellArg name} ${lib.escapeShellArg profile.dir} ${lib.escapeShellArg (profileVersionId name profile)}"
        ) cfg.profiles
      )}
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

            options.mcVersion = lib.mkOption {
              type = lib.types.str;
            };

            options.loaderVersion = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };

            options.loader = lib.mkOption {
              type = lib.types.enum [
                "vanilla"
                "fabric"
                "quilt"
                "neoforge"
                "forge"
              ];
            };
          }
        )
      );
      default = { };
    };
  };

  config = {
    home.file = profileFiles;

    home.packages = lib.mkIf (cfg.profiles != { }) [ minecraft-provision ];
  };
}
