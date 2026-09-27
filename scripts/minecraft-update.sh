#!/usr/bin/env bash

set -euo pipefail

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

function read_minecraft_version() {
    local version

    version="$(sed -n 's/^minecraft = "\(.*\)"$/\1/p' minecraft/latest/pack.toml)"

    if [[ -z "${version}" ]]; then
        printf 'Could not read the minecraft version from minecraft/latest/pack.toml\n' >&2
        exit 1
    fi

    printf '%s' "${version}"
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

function main() (
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

    update_packs

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

    local temporary
    temporary="$(mktemp)"
    trap 'rm -f -- "${temporary}"' EXIT

    {
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
    } >"${temporary}"

    if cmp --silent "${temporary}" minecraft/installers.nix; then
        return
    fi

    mv -f -- "${temporary}" minecraft/installers.nix
)

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
