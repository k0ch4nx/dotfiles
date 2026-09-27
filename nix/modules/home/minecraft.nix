{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.minecraft;

  minecraftDir = ../../../minecraft;

  fabricInstaller = pkgs.fetchurl {
    name = "fabric-installer-1.1.2.jar";
    url = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.1.2/fabric-installer-1.1.2.jar";
    hash = "sha256-YeA1v3v3AVPhJ0QM403kfJA28KLQxl0VKUVL01zu/k8=";
  };

  quiltInstaller = pkgs.fetchurl {
    name = "quilt-installer-0.15.1.jar";
    url = "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/0.15.1/quilt-installer-0.15.1.jar";
    hash = "sha256-CiKROMqhuH/Y9WIgOEEGlvmLuFhxonlkDnACQExNDcI=";
  };

  neoforgeInstaller = pkgs.fetchurl {
    name = "neoforge-26.3.0.23-beta-installer.jar";
    url = "https://maven.neoforged.net/releases/net/neoforged/neoforge/26.3.0.23-beta/neoforge-26.3.0.23-beta-installer.jar";
    hash = "sha256-RuxzbFf4LUKV2Q5/T6aZibEAzZFXK2A3xlwole7tRvU=";
  };

  forgeInstaller = pkgs.fetchurl {
    name = "forge-26.3-66.0.5-installer.jar";
    url = "https://maven.minecraftforge.net/net/minecraftforge/forge/26.3-66.0.5/forge-26.3-66.0.5-installer.jar";
    hash = "sha256-Daw1s9a9paO/Fc0zk2ObAfGXapWPtK/AZAYQmAY/DrQ=";
  };

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

  profileLinks = lib.mapAttrs (
    name: entries:
    lib.mapAttrs (
      subdir: subdirEntries:
      pkgs.linkFarm "minecraft-${name}-${subdir}" (
        map (entry: {
          name = entry.filename;
          path = entry.file;
        }) subdirEntries
      )
    ) (lib.groupBy (entry: entry.subdir) entries)
  ) profilePacks;

  activationScript = lib.concatStringsSep "\n" (
    lib.flatten (
      lib.mapAttrsToList (
        name: subdirLinks:
        lib.mapAttrsToList (
          subdir: linkFarm:
          let
            profileDir = cfg.profiles.${name}.dir;
            target = "${profileDir}/${subdir}";
          in
          ''
            if [[ -e ${lib.escapeShellArg target} && ! -L ${lib.escapeShellArg target} ]]; then
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf ${lib.escapeShellArg target}
            fi
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg profileDir}
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn ${lib.escapeShellArg (toString linkFarm)} ${lib.escapeShellArg target}
          ''
        ) subdirLinks
      ) profileLinks
    )
  );

  profileLoaderVersion =
    name: profile:
    if profile.loaderVersion != null then
      profile.loaderVersion
    else
      throw "minecraft.profiles.${name}.loaderVersion is required when loader is \"${profile.loader}\"";

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

  loaderSupport = {
    fabric = {
      function = ''
        install_fabric() {
          local mcVersion="$1"
          local loaderVersion="$2"

          java -jar ${fabricInstaller} client \
            -dir "$baseDir" \
            -mcversion "$mcVersion" \
            -loader "$loaderVersion" \
            -noprofile
        }
      '';
      command =
        install:
        "install_fabric ${lib.escapeShellArg install.mcVersion} ${lib.escapeShellArg install.loaderVersion}";
    };

    quilt = {
      function = ''
        install_quilt() {
          local mcVersion="$1"
          local loaderVersion="$2"

          java -jar ${quiltInstaller} install client \
            "$mcVersion" \
            "$loaderVersion" \
            --install-dir="$baseDir" \
            --no-profile
        }
      '';
      command =
        install:
        "install_quilt ${lib.escapeShellArg install.mcVersion} ${lib.escapeShellArg install.loaderVersion}";
    };

    neoforge = {
      function = ''
        install_neoforge() {
          if [[ ! -f "$launcherProfiles" ]]; then
            echo '{}' > "$launcherProfiles"
          fi

          java -jar ${neoforgeInstaller} --install-client "$baseDir"
        }
      '';
      command = _: "install_neoforge";
    };

    forge = {
      function = ''
        install_forge() {
          local microsoftStoreProfiles="$baseDir/launcher_profiles_microsoft_store.json"

          if [[ ! -f "$launcherProfiles" && ! -f "$microsoftStoreProfiles" ]]; then
            echo '{}' > "$launcherProfiles"
          fi

          java -jar ${forgeInstaller} --installClient "$baseDir"
        }
      '';
      command = _: "install_forge";
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
    home.activation.minecraftMods = lib.mkIf (activationScript != "") (
      lib.hm.dag.entryAfter [ "writeBoundary" ] activationScript
    );

    home.packages = lib.mkIf (cfg.profiles != { }) [ minecraft-provision ];
  };
}
