#!/usr/bin/env bash

set -euo pipefail

nixpkgs_rev=''

function nixpkgs_run() {
    local package="$1"
    shift

    if [[ -n "${nixpkgs_rev}" ]]; then
        nix run "github:NixOS/nixpkgs/${nixpkgs_rev}#${package}" -- "$@"
    else
        nix run "nixpkgs#${package}" -- "$@"
    fi
}

function resolve_nixpkgs_rev() {
    local rev=''

    if ! rev="$(
        nix eval --impure --raw --expr '
            let
                lock = builtins.fromJSON (builtins.readFile ./flake.lock);
                root = lock.nodes.${lock.root};
            in
            lock.nodes.${root.inputs.nixpkgs}.locked.rev
        ' 2>/dev/null
    )"; then
        rev=''
    fi

    if [[ -z "${rev}" ]]; then
        if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
            printf 'Could not resolve the nixpkgs revision from flake.lock\n' >&2
            exit 1
        fi

        printf 'warning: could not resolve the nixpkgs revision from flake.lock; using the nixpkgs registry\n' >&2
    fi

    printf '%s' "${rev}"
}

function pack_directories() {
    local pack_directory

    for pack_directory in minecraft/*/; do
        if [[ -f "${pack_directory}/pack.toml" ]]; then
            printf '%s\n' "${pack_directory%/}"
        fi
    done
}

function pack_version() {
    local pack_directory="$1"
    local key="$2"

    sed -n "s/^${key} = \"\(.*\)\"$/\1/p" "${pack_directory}/pack.toml"
}

function set_pack_version() {
    local pack_directory="$1"
    local key="$2"
    local version="$3"
    local content

    content="$(sed "s/^${key} = \".*\"$/${key} = \"${version}\"/" "${pack_directory}/pack.toml")"

    printf '%s\n' "${content}" >"${pack_directory}/pack.toml"
}

function loader_pairs() {
    local pack_directory
    local loader
    local minecraft_version
    local loader_version

    while read -r pack_directory; do
        for loader in fabric quilt neoforge forge; do
            minecraft_version="$(pack_version "${pack_directory}" minecraft)"
            loader_version="$(pack_version "${pack_directory}" "${loader}")"

            if [[ -n "${minecraft_version}" && -n "${loader_version}" ]]; then
                printf '%s %s %s\n' "${loader}" "${minecraft_version}" "${loader_version}"
            fi
        done
    done < <(pack_directories) | sort -u
}

function latest_fabric_installer() {
    local version

    version="$(
        curl --fail --silent --show-error --location \
            'https://meta.fabricmc.net/v2/versions/installer' \
            | nixpkgs_run jq --raw-output '[.[] | select(.stable)][0].version'
    )"

    if [[ -z "${version}" || "${version}" == 'null' ]]; then
        printf 'Could not determine the latest fabric installer version\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function latest_quilt_installer() {
    local version

    version="$(
        curl --fail --silent --show-error --location \
            'https://meta.quiltmc.org/v3/versions/installer' \
            | nixpkgs_run jq --raw-output '.[0].version'
    )"

    if [[ -z "${version}" || "${version}" == 'null' ]]; then
        printf 'Could not determine the latest quilt installer version\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function neoforge_prefix() {
    local minecraft_version="$1"

    if [[ "${minecraft_version}" =~ ^1\.([0-9]+)\.([0-9]+)$ ]]; then
        printf '%s.%s.' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return
    fi

    if [[ "${minecraft_version}" =~ ^1\.([0-9]+)$ ]]; then
        printf '%s.0.' "${BASH_REMATCH[1]}"
        return
    fi

    if [[ "${minecraft_version}" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        printf '%s.%s.' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return
    fi

    printf 'Unsupported Minecraft version for neoforge: %s\n' "${minecraft_version}" >&2
    return 1
}

function latest_neoforge_installer() {
    local minecraft_version="$1"
    local prefix
    local version

    prefix="$(neoforge_prefix "${minecraft_version}")" || return 1

    version="$(
        curl --fail --silent --show-error --location \
            'https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge' \
            | nixpkgs_run jq --arg prefix "${prefix}" --raw-output \
                '[.versions[] | select(startswith($prefix))] | last'
    )"

    if [[ -z "${version}" || "${version}" == 'null' ]]; then
        printf 'Could not determine the latest neoforge installer version\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function latest_forge_installer() {
    local minecraft_version="$1"
    local version

    version="$(
        curl --fail --silent --show-error --location \
            'https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json' \
            | nixpkgs_run jq --arg key "${minecraft_version}-latest" --raw-output '.promos[$key]'
    )"

    if [[ -z "${version}" || "${version}" == 'null' ]]; then
        printf 'Could not determine the latest forge installer version\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function latest_loader_version() {
    local loader="$1"
    local minecraft_version="$2"
    local version

    case "${loader}" in
    fabric)
        version="$(
            curl --fail --silent --show-error --location \
                "https://meta.fabricmc.net/v2/versions/loader/${minecraft_version}" \
                | nixpkgs_run jq --raw-output '([.[] | select(.loader.stable)][0] // .[0]).loader.version'
        )"
        ;;
    quilt)
        version="$(
            curl --fail --silent --show-error --location \
                "https://meta.quiltmc.org/v3/versions/loader/${minecraft_version}" \
                | nixpkgs_run jq --raw-output '.[0].loader.version'
        )"
        ;;
    neoforge)
        version="$(latest_neoforge_installer "${minecraft_version}")"
        ;;
    forge)
        version="$(latest_forge_installer "${minecraft_version}")"
        ;;
    *)
        printf 'Unsupported loader: %s\n' "${loader}" >&2
        exit 1
        ;;
    esac

    if [[ -z "${version}" || "${version}" == 'null' ]]; then
        printf 'Could not determine the latest %s loader version for %s\n' "${loader}" "${minecraft_version}" >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function installer_hash() {
    local url="$1"
    local hash

    hash="$(
        nix store prefetch-file --json --hash-type sha256 "${url}" \
            | nixpkgs_run jq --raw-output '.hash'
    )"

    if [[ -z "${hash}" || "${hash}" == 'null' ]]; then
        printf 'Could not fetch the installer hash for %s\n' "${url}" >&2
        exit 1
    fi

    printf '%s' "${hash}"
}

function installer_name() {
    local loader="$1"
    local minecraft_version="$2"
    local version="$3"

    case "${loader}" in
    fabric)
        printf 'fabric-installer-%s.jar' "${version}"
        ;;
    quilt)
        printf 'quilt-installer-%s.jar' "${version}"
        ;;
    neoforge)
        printf 'neoforge-%s-installer.jar' "${version}"
        ;;
    forge)
        printf 'forge-%s-%s-installer.jar' "${minecraft_version}" "${version}"
        ;;
    *)
        printf 'Unsupported loader: %s\n' "${loader}" >&2
        exit 1
        ;;
    esac
}

function installer_url() {
    local loader="$1"
    local minecraft_version="$2"
    local version="$3"

    case "${loader}" in
    fabric)
        printf 'https://maven.fabricmc.net/net/fabricmc/fabric-installer/%s/fabric-installer-%s.jar' "${version}" "${version}"
        ;;
    quilt)
        printf 'https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/%s/quilt-installer-%s.jar' "${version}" "${version}"
        ;;
    neoforge)
        printf 'https://maven.neoforged.net/releases/net/neoforged/neoforge/%s/neoforge-%s-installer.jar' "${version}" "${version}"
        ;;
    forge)
        printf 'https://maven.minecraftforge.net/net/minecraftforge/forge/%s-%s/forge-%s-%s-installer.jar' "${minecraft_version}" "${version}" "${minecraft_version}" "${version}"
        ;;
    *)
        printf 'Unsupported loader: %s\n' "${loader}" >&2
        exit 1
        ;;
    esac
}

function installer_version() {
    local loader="$1"
    local loader_version="$2"

    case "${loader}" in
    fabric)
        latest_fabric_installer
        ;;
    quilt)
        latest_quilt_installer
        ;;
    neoforge | forge)
        printf '%s' "${loader_version}"
        ;;
    *)
        printf 'Unsupported loader: %s\n' "${loader}" >&2
        exit 1
        ;;
    esac
}

function write_installer_entry() {
    local indent="$1"
    local loader="$2"
    local minecraft_version="$3"
    local version="$4"
    local name
    local url
    local hash

    name="$(installer_name "${loader}" "${minecraft_version}" "${version}")"
    url="$(installer_url "${loader}" "${minecraft_version}" "${version}")"
    hash="$(installer_hash "${url}")"

    printf '%sname = "%s";\n' "${indent}" "${name}"
    printf '%surl = "%s";\n' "${indent}" "${url}"
    printf '%shash = "%s";\n' "${indent}" "${hash}"
}

function write_loader_installers() {
    local loader="$1"
    local minecraft_version
    local loader_version
    local previous_minecraft_version=""
    local version

    printf '  %s = {\n' "${loader}"

    case "${loader}" in
    fabric | quilt)
        read -r _ minecraft_version loader_version

        version="$(installer_version "${loader}" "${loader_version}")"
        write_installer_entry '    ' "${loader}" "${minecraft_version}" "${version}"
        ;;
    neoforge | forge)
        while read -r _ minecraft_version loader_version; do
            if [[ "${minecraft_version}" != "${previous_minecraft_version}" ]]; then
                if [[ -n "${previous_minecraft_version}" ]]; then
                    printf '    };\n'
                fi

                printf '    "%s" = {\n' "${minecraft_version}"
                previous_minecraft_version="${minecraft_version}"
            fi

            printf '      "%s" = {\n' "${loader_version}"
            write_installer_entry '        ' "${loader}" "${minecraft_version}" "${loader_version}"
            printf '      };\n'
        done

        printf '    };\n'
        ;;
    esac

    printf '  };\n'
}

function write_installers() {
    local pairs
    local loader

    pairs="$(loader_pairs)"

    if [[ -z "${pairs}" ]]; then
        printf '{ }\n'
        return
    fi

    printf '{\n'

    while read -r loader; do
        write_loader_installers "${loader}" < <(grep "^${loader} " <<<"${pairs}")
    done < <(cut -d ' ' -f 1 <<<"${pairs}" | uniq)

    printf '}\n'
}

function sync_pack_versions() {
    local loader="$1"
    local minecraft_version="$2"
    local version="$3"
    local pack_directory
    local current

    while read -r pack_directory; do
        if [[ "$(pack_version "${pack_directory}" minecraft)" != "${minecraft_version}" ]]; then
            continue
        fi

        current="$(pack_version "${pack_directory}" "${loader}")"

        if [[ -z "${current}" || "${current}" == "${version}" ]]; then
            continue
        fi

        set_pack_version "${pack_directory}" "${loader}" "${version}"
    done < <(pack_directories)
}

function write_loaders() {
    local pairs
    local loader
    local minecraft_version
    local previous_loader=""
    local version

    pairs="$(loader_pairs | cut -d ' ' -f 1,2 | uniq)"

    if [[ -z "${pairs}" ]]; then
        printf '{ }\n'
        return
    fi

    printf '{\n'

    while read -r loader minecraft_version; do
        if [[ "${loader}" != "${previous_loader}" ]]; then
            if [[ -n "${previous_loader}" ]]; then
                printf '  };\n'
            fi

            printf '  %s = {\n' "${loader}"
            previous_loader="${loader}"
        fi

        version="$(latest_loader_version "${loader}" "${minecraft_version}")"
        sync_pack_versions "${loader}" "${minecraft_version}" "${version}"

        printf '    "%s" = "%s";\n' "${minecraft_version}" "${version}"
    done <<<"${pairs}"

    printf '  };\n'
    printf '}\n'
}

function run_packwiz() {
    local output
    local status

    if output="$(nixpkgs_run packwiz "$@" 2>&1)"; then
        status=0
    else
        status=$?
    fi

    if [[ -n "${output}" ]]; then
        printf '%s\n' "${output}"
    fi

    if ((status != 0)); then
        printf 'packwiz %s failed with exit status %s\n' "$*" "${status}" >&2
        return "${status}"
    fi
}

function pack_files() {
    local pack_directory="$1"

    find "${pack_directory}" -type f -name '*.pw.toml' -print | LC_ALL=C sort
}

function update_packs() {
    local pack_directory
    local file
    local name

    for pack_directory in minecraft/*/; do
        if [[ ! -f "${pack_directory}/pack.toml" ]]; then
            continue
        fi

        (
            cd -- "${pack_directory}"

            while IFS= read -r file; do
                if [[ -z "${file}" ]]; then
                    continue
                fi

                name="$(basename -- "${file}" .pw.toml)"

                if ! run_packwiz update -y "${name}"; then
                    exit 1
                fi
            done < <(pack_files ".")

            run_packwiz refresh
        )
    done
}

function replace_if_changed() {
    local source="$1"
    local destination="$2"

    if cmp --silent "${source}" "${destination}"; then
        return
    fi

    cat "${source}" >"${destination}"
}

function sync_directory() {
    local source="$1"
    local destination="$2"
    local entry
    local relative

    while IFS= read -r -d '' entry; do
        relative="${entry#"${source}/"}"

        mkdir -p -- "${destination}/${relative}"
    done < <(find "${source}" -mindepth 1 -type d -print0)

    while IFS= read -r -d '' entry; do
        relative="${entry#"${source}/"}"

        replace_if_changed "${entry}" "${destination}/${relative}"
    done < <(find "${source}" -mindepth 1 -type f -print0)

    while IFS= read -r -d '' entry; do
        relative="${entry#"${destination}/"}"

        if [[ -e "${source}/${relative}" ]]; then
            continue
        fi

        if [[ -d "${entry}" ]]; then
            rmdir -- "${entry}" 2>/dev/null || true
        else
            rm -f -- "${entry}"
        fi
    done < <(find "${destination}" -mindepth 1 -depth -print0)
}

function hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1"
    else
        shasum -a 256 "$1"
    fi
}

function tree_hash() {
    local directory="$1"

    (
        cd -- "${directory}" || exit 1

        find . -mindepth 1 -type f -print | LC_ALL=C sort | while IFS= read -r file; do
            printf '%s ' "${file}"
            hash_file "${file}"
        done
    )
}

function update_lock_path() {
    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        printf '%s' "${MINECRAFT_UPDATE_LOCK:-${RUNNER_TEMP:-/tmp}/minecraft-update.lock}"
    else
        printf '%s' "${MINECRAFT_UPDATE_LOCK:-${XDG_STATE_HOME:-$HOME/.local/state}/minecraft-update.lock}"
    fi
}

function lock_unavailable() {
    local lock="$1"
    local reason="$2"

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        printf 'error: could not acquire the minecraft update lock %s: %s\n' "${lock}" "${reason}" >&2
        exit 1
    fi

    printf 'warning: could not acquire the minecraft update lock %s: %s; skipping the minecraft update\n' "${lock}" "${reason}" >&2
    exit 0
}

function acquire_update_lock() {
    local lock
    local owner
    local readback

    lock="$(update_lock_path)"

    if ! mkdir -p -- "$(dirname -- "${lock}")" 2>/dev/null; then
        lock_unavailable "${lock}" 'the lock directory could not be created'
    fi

    if ! mkdir -- "${lock}" 2>/dev/null; then
        lock_unavailable "${lock}" 'another update is running; remove the lock directory by hand if it is stale'
    fi

    owner="$$-${RANDOM}-$(date +%s)"

    if ! printf '%s\n' "${owner}" >"${lock}/owner" 2>/dev/null; then
        rm -rf -- "${lock}" 2>/dev/null || true
        lock_unavailable "${lock}" 'the lock could not be claimed'
    fi

    readback=''

    if [[ -f "${lock}/owner" ]]; then
        read -r readback <"${lock}/owner" || readback=''
    fi

    if [[ "${readback}" != "${owner}" ]]; then
        lock_unavailable "${lock}" 'the lock was acquired twice'
    fi

    update_lock_owner="${owner}"
}

function release_update_lock() {
    local lock
    local owner

    [[ -n "${update_lock_owner:-}" ]] || return 0

    lock="$(update_lock_path)"
    owner=''

    if [[ -f "${lock}/owner" ]]; then
        read -r owner <"${lock}/owner" || owner=''
    fi

    if [[ "${owner}" == "${update_lock_owner}" ]]; then
        rm -rf -- "${lock}"
    fi

    update_lock_owner=''
}

function cleanup_update_minecraft() {
    local status=$?

    if [[ -n "${staging:-}" ]]; then
        rm -rf -- "${staging}" || true
    fi

    if [[ -n "${loaders_temporary:-}" ]]; then
        rm -f -- "${loaders_temporary}" "${installers_temporary:-}" || true
    fi

    if [[ -n "${backup_root:-}" ]]; then
        if ((status != 0)) && [[ -d "${backup:-}" ]]; then
            printf 'warning: keeping the minecraft backup at %s\n' "${backup}" >&2
        else
            rm -rf -- "${backup_root}" || true
        fi
    fi

    release_update_lock || true

    exit "${status}"
}

function publish_minecraft() (
    set -e

    local staging="$1"
    local backup="$2"
    local baseline="$3"
    local loaders_temporary="$4"
    local installers_temporary="$5"
    local backup_ready=0
    local published=0
    local preserved=''
    local restored=''
    local current
    local original
    local staged

    restore_minecraft() {
        restored=''

        if ! restored="$(mktemp -d)"; then
            restored=''
            return 1
        fi

        if ! cp -R -- "${backup}" "${restored}/minecraft"; then
            printf 'error: the committed minecraft data could not be staged for the restore; keeping %s\n' "${restored}" >&2
            return 1
        fi

        if ! mv -- minecraft "${restored}/retired"; then
            printf 'error: the published minecraft data could not be retired for the restore; keeping %s\n' "${restored}" >&2
            return 1
        fi

        if ! mv -- "${restored}/minecraft" minecraft; then
            if ! mv -- "${restored}/retired" minecraft 2>/dev/null; then
                cp -R -- "${restored}/retired" minecraft 2>/dev/null || true
            fi

            printf 'error: the committed minecraft data could not be put back in place; keeping %s\n' "${restored}" >&2
            return 1
        fi

        if [[ ! -d minecraft || "$(tree_hash minecraft)" != "${original}" ]]; then
            printf 'error: the restored minecraft data does not match the committed data; keeping %s\n' "${restored}" >&2
            return 1
        fi

        rm -rf -- "${restored}" || true

        return 0
    }

    preserve_backup() {
        local target

        target="${TMPDIR:-/tmp}/minecraft-restore-backup.$$.$(date +%s)"

        if ( cd -- "${backup_root}" && cp -R -- minecraft "${target}" ); then
            preserved="${target}"
            return 0
        fi

        return 1
    }

    publish_failed() {
        local status=$?
        local preserve_status=0
        local restore_status=0

        if ((published == 1)); then
            exit "${status}"
        fi

        trap - EXIT

        if ((backup_ready == 1)); then
            preserve_status=0
            preserve_backup || preserve_status=$?

            restore_status=0
            restore_minecraft || restore_status=$?

            if ((restore_status == 0)) && [[ "$(tree_hash minecraft)" == "${original}" ]]; then
                if [[ -n "${preserved}" ]]; then
                    rm -rf -- "${preserved}" || true
                    rm -rf -- "${backup_root}" || true
                fi

                if ((preserve_status == 0)); then
                    printf 'error: the minecraft update failed; kept the committed minecraft data\n' >&2
                else
                    printf 'error: the minecraft update failed; restored the committed minecraft data but the backup %s could not be kept\n' "${backup}" >&2
                fi

                exit 1
            fi

            if [[ -n "${preserved}" ]]; then
                printf 'error: the committed minecraft data could not be restored; kept the backup at %s\n' "${preserved}" >&2
            else
                printf 'error: the committed minecraft data could not be restored and the backup %s could not be kept\n' "${backup}" >&2
            fi

            if [[ -n "${restored}" ]]; then
                printf 'error: the partial restore state is kept at %s\n' "${restored}" >&2
            fi

            exit 1
        fi

        printf 'error: the minecraft update failed; kept the committed minecraft data\n' >&2
        exit 1
    }

    trap publish_failed EXIT

    cp -- "${loaders_temporary}" "${staging}/minecraft/loaders.nix"
    cp -- "${installers_temporary}" "${staging}/minecraft/installers.nix"

    current="$(tree_hash minecraft)"

    if [[ "${current}" != "${baseline}" ]]; then
        printf 'error: the committed minecraft data changed while the update was staged\n' >&2
        exit 1
    fi

    original="${current}"

    cp -R -- minecraft "${backup}"
    backup_ready=1

    sync_directory "${staging}/minecraft" minecraft
    replace_if_changed "${loaders_temporary}" minecraft/loaders.nix
    replace_if_changed "${installers_temporary}" minecraft/installers.nix

    staged="$(tree_hash "${staging}/minecraft")"
    current="$(tree_hash minecraft)"

    if [[ "${current}" != "${staged}" ]]; then
        printf 'error: the published minecraft data does not match the staged data\n' >&2
        exit 1
    fi

    published=1
)

function update_minecraft() (
    set +x
    set -e

    local repository
    repository="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"

    cd -- "${repository}"

    local staging=''
    local loaders_temporary=''
    local installers_temporary=''
    local backup_root=''
    local backup=''
    local baseline=''

    trap cleanup_update_minecraft EXIT

    acquire_update_lock

    baseline="$(tree_hash "${repository}/minecraft")"

    nixpkgs_rev="$(resolve_nixpkgs_rev)"

    staging="$(mktemp -d)"
    loaders_temporary="$(mktemp)"
    installers_temporary="$(mktemp)"
    backup_root="$(mktemp -d)"
    backup="${backup_root}/minecraft"

    cp -R -- minecraft "${staging}/minecraft"

    cd -- "${staging}"

    write_loaders >"${loaders_temporary}"
    update_packs
    write_installers >"${installers_temporary}"

    cd -- "${repository}"

    publish_minecraft "${staging}" "${backup}" "${baseline}" "${loaders_temporary}" "${installers_temporary}"
)

function main() (
    if [[ "${SKIP_UPDATES:-}" == "1" ]]; then
        return 0
    fi

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]] && [[ "$(uname -s)" != 'Darwin' ]]; then
        printf 'warning: minecraft provisioning is not enabled on this host; skipping the minecraft update\n' >&2
        return 0
    fi

    if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
        update_minecraft
        return 0
    fi

    local pid
    local status

    update_minecraft &
    pid=$!

    status=0
    wait "${pid}" || status=$?

    if ((status != 0)); then
        printf 'warning: the minecraft update failed; keeping the committed minecraft data\n' >&2
    fi

    return "${status}"
)

main
