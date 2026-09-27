{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.minecraft;

  minecraftDir = ../../../../minecraft;

  fabricInstaller = pkgs.fetchurl {
    name = "fabric-installer-1.1.2.jar";
    url = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.1.2/fabric-installer-1.1.2.jar";
    hash = "sha256-YeA1v3v3AVPhJ0QM403kfJA28KLQxl0VKUVL01zu/k8=";
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

  versionId = "fabric-loader-${cfg.loaderVersion}-${cfg.mcVersion}";

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
      versionId=${lib.escapeShellArg versionId}

      launcherRunning=0
      if pgrep -x Minecraft >/dev/null 2>&1; then
        echo "warning: Minecraft launcher is running; skipping launcher_profiles.json update" >&2
        launcherRunning=1
      fi

      java -jar ${fabricInstaller} client \
        -dir "$baseDir" \
        -mcversion ${lib.escapeShellArg cfg.mcVersion} \
        -loader ${lib.escapeShellArg cfg.loaderVersion} \
        -noprofile

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
          "merge_profile ${lib.escapeShellArg name} ${lib.escapeShellArg name} ${lib.escapeShellArg profile.dir}"
        ) cfg.profiles
      )}
    '';
  };
in
{
  options.minecraft = {
    baseDir = lib.mkOption {
      type = lib.types.str;
      description = "Minecraft base directory, the launcher's installation root.";
    };

    mcVersion = lib.mkOption {
      type = lib.types.str;
      description = "Minecraft version installed by the Fabric installer.";
    };

    loaderVersion = lib.mkOption {
      type = lib.types.str;
      description = "Fabric loader version installed by the Fabric installer.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options.dir = lib.mkOption {
              type = lib.types.str;
              default = "${cfg.baseDir}/profiles/${name}";
              description = "Directory the profile's mods and shaderpacks are linked into.";
            };
          }
        )
      );
      default = { };
      description = "Packwiz profiles managed on this host.";
    };
  };

  config = {
    minecraft = {
      baseDir = "${config.home.homeDirectory}/Library/Application Support/minecraft";
      mcVersion = "26.2";
      loaderVersion = "0.19.5";
      profiles = {
        vanilla = { };
        performance = { };
        shaders = { };
        experimental = { };
      };
    };

    home.activation.minecraftMods = lib.mkIf (activationScript != "") (
      lib.hm.dag.entryAfter [ "writeBoundary" ] activationScript
    );

    home.packages = [ minecraft-provision ];
  };
}
