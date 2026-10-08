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

    if grep --quiet --ignore-case -E '(^|[^[:alnum:]_-])(failed|error)([^[:alnum:]_-]|$)' <<<"${output}"; then
        printf 'packwiz %s reported a failure\n' "$*" >&2
        return 1
    fi
}

function update_packs() {
    local pack_directory

    for pack_directory in minecraft/*/; do
        if [[ ! -f "${pack_directory}/pack.toml" ]]; then
            continue
        fi

        (
            cd -- "${pack_directory}"

            run_packwiz update --all -y
            run_packwiz refresh
        )
    done
}

function verify_packs() {
    local repository="$1"
    local checker="${repository}/scripts/check-minecraft-deps.py"
    local pack_directory
    local packs=()

    if [[ ! -f "${checker}" ]]; then
        if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
            printf 'Expected the dependency checker at %s\n' "${checker}" >&2
            exit 1
        fi

        printf 'warning: %s does not exist; skipping the dependency check\n' "${checker}" >&2
        return 0
    fi

    while read -r pack_directory; do
        packs+=("${pack_directory}")
    done < <(pack_directories)

    if (( ${#packs[@]} == 0 )); then
        return 0
    fi

    python3 "${checker}" "${packs[@]}"
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

function update_minecraft() (
    set +x
    set -e

    local repository
    repository="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"

    cd -- "${repository}"

    nixpkgs_rev="$(resolve_nixpkgs_rev)"

    local staging
    local loaders_temporary
    local installers_temporary
    staging="$(mktemp -d)"
    loaders_temporary="$(mktemp)"
    installers_temporary="$(mktemp)"
    trap 'rm -rf -- "${staging}"; rm -f -- "${loaders_temporary}" "${installers_temporary}"' EXIT

    cp -R -- minecraft "${staging}/minecraft"

    cd -- "${staging}"

    write_loaders >"${loaders_temporary}"
    update_packs
    write_installers >"${installers_temporary}"
    verify_packs "${repository}"

    cd -- "${repository}"

    sync_directory "${staging}/minecraft" minecraft
    replace_if_changed "${loaders_temporary}" minecraft/loaders.nix
    replace_if_changed "${installers_temporary}" minecraft/installers.nix

    if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
        git add -- minecraft
    fi
)

function main() (
    if [[ "${SKIP_UPDATES:-}" == "1" ]]; then
        return 0
    fi

    if [[ "${GITHUB_ACTIONS:-}" != 'true' ]] && ! command -v minecraft-provision >/dev/null 2>&1; then
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

    return 0
)

main
