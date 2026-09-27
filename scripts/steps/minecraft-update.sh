#!/usr/bin/env bash

set -euo pipefail

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

function read_minecraft_version() {
    local version

    version="$(pack_version minecraft/latest minecraft)"

    if [[ -z "${version}" ]]; then
        printf 'Could not read the minecraft version from minecraft/latest/pack.toml\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function loader_pairs() {
    local pack_directory
    local loader

    while read -r pack_directory; do
        for loader in fabric quilt neoforge forge; do
            if [[ -n "$(pack_version "${pack_directory}" "${loader}")" ]]; then
                printf '%s %s\n' "${loader}" "$(pack_version "${pack_directory}" minecraft)"
            fi
        done
    done < <(pack_directories) | sort -u
}

function latest_fabric_installer() {
    local version

    version="$(
        curl --fail --silent --show-error --location \
            'https://meta.fabricmc.net/v2/versions/installer' \
            | jq --raw-output '[.[] | select(.stable)][0].version'
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
            | jq --raw-output '.[0].version'
    )"

    if [[ -z "${version}" || "${version}" == 'null' ]]; then
        printf 'Could not determine the latest quilt installer version\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
}

function latest_neoforge_installer() {
    local minecraft_version="$1"
    local version

    version="$(
        curl --fail --silent --show-error --location \
            'https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge' \
            | jq --arg prefix "${minecraft_version}.0" --raw-output \
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
            | jq --arg key "${minecraft_version}-latest" --raw-output '.promos[$key]'
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
                | jq --raw-output '([.[] | select(.loader.stable)][0] // .[0]).loader.version'
        )"
        ;;
    quilt)
        version="$(
            curl --fail --silent --show-error --location \
                "https://meta.quiltmc.org/v3/versions/loader/${minecraft_version}" \
                | jq --raw-output '.[0].loader.version'
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
            | jq --raw-output '.hash'
    )"

    if [[ -z "${hash}" || "${hash}" == 'null' ]]; then
        printf 'Could not fetch the installer hash for %s\n' "${url}" >&2
        exit 1
    fi

    printf '%s' "${hash}"
}

function write_installer() {
    local loader="$1"
    local name="$2"
    local url="$3"

    printf '  %s = {\n' "${loader}"
    printf '    name = "%s";\n' "${name}"
    printf '    url = "%s";\n' "${url}"
    printf '    hash = "%s";\n' "$(installer_hash "${url}")"
    printf '  };\n'
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

    pairs="$(loader_pairs)"

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

function write_installers() {
    local minecraft_version
    local fabric_version
    local quilt_version
    local neoforge_version
    local forge_version

    minecraft_version="$(read_minecraft_version)"
    fabric_version="$(latest_fabric_installer)"
    quilt_version="$(latest_quilt_installer)"
    neoforge_version="$(latest_neoforge_installer "${minecraft_version}")"
    forge_version="$(latest_forge_installer "${minecraft_version}")"

    printf '{\n'
    write_installer \
        fabric \
        "fabric-installer-${fabric_version}.jar" \
        "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${fabric_version}/fabric-installer-${fabric_version}.jar"
    write_installer \
        quilt \
        "quilt-installer-${quilt_version}.jar" \
        "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/${quilt_version}/quilt-installer-${quilt_version}.jar"
    write_installer \
        neoforge \
        "neoforge-${neoforge_version}-installer.jar" \
        "https://maven.neoforged.net/releases/net/neoforged/neoforge/${neoforge_version}/neoforge-${neoforge_version}-installer.jar"
    write_installer \
        forge \
        "forge-${minecraft_version}-${forge_version}-installer.jar" \
        "https://maven.minecraftforge.net/net/minecraftforge/forge/${minecraft_version}-${forge_version}/forge-${minecraft_version}-${forge_version}-installer.jar"
    printf '}\n'
}

function update_packs() {
    local pack_directory

    for pack_directory in minecraft/*/; do
        if [[ ! -f "${pack_directory}/pack.toml" ]]; then
            continue
        fi

        (
            cd -- "${pack_directory}"

            nix run nixpkgs#packwiz -- update --all -y
            nix run nixpkgs#packwiz -- refresh
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

function main() (
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."

    local loaders_temporary
    local installers_temporary

    loaders_temporary="$(mktemp)"
    installers_temporary="$(mktemp)"
    trap 'rm -f -- "${loaders_temporary}" "${installers_temporary}"' EXIT

    write_loaders >"${loaders_temporary}"
    update_packs
    write_installers >"${installers_temporary}"

    replace_if_changed "${loaders_temporary}" minecraft/loaders.nix
    replace_if_changed "${installers_temporary}" minecraft/installers.nix
)

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
