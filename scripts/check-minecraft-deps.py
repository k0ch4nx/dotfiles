import hashlib
import json
import re
import shutil
import sys
import tempfile
import tomllib
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path


class CheckError(Exception):
    pass


VERSION_RE = re.compile(
    r"^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.\-]*))?(?:\+([0-9A-Za-z.\-]+))?$"
)
TERM_RE = re.compile(r"^(>=|<=|>|<|~|\^|=)?(.*)$")
HASHERS = {
    "md5": hashlib.md5,
    "sha1": hashlib.sha1,
    "sha256": hashlib.sha256,
    "sha512": hashlib.sha512,
}
WILDCARDS = {"x", "X", "*"}
LOADERS = ("fabric", "quilt", "neoforge", "forge")


def parse_version(text):
    match = VERSION_RE.match(text.strip())
    if not match:
        raise CheckError(f"invalid version {text!r}")
    numbers = [
        int(match.group(index)) if match.group(index) is not None else 0
        for index in (1, 2, 3)
    ]
    prerelease = None
    if match.group(4) is not None:
        prerelease = match.group(4).split(".") if match.group(4) else []
    return (numbers[0], numbers[1], numbers[2], prerelease)


def compare_prerelease(left, right):
    if left is None:
        return 0 if right is None else 1
    if right is None:
        return -1
    for left_part, right_part in zip(left, right):
        if left_part == right_part:
            continue
        left_number = left_part.isdigit()
        right_number = right_part.isdigit()
        if left_number and right_number:
            return -1 if int(left_part) < int(right_part) else 1
        if left_number != right_number:
            return -1 if left_number else 1
        return -1 if left_part < right_part else 1
    if len(left) == len(right):
        return 0
    return -1 if len(left) < len(right) else 1


def compare_versions(left, right):
    for left_part, right_part in zip(left[:3], right[:3]):
        if left_part != right_part:
            return -1 if left_part < right_part else 1
    return compare_prerelease(left[3], right[3])


def parse_range_version(text):
    text = text.strip()
    if "+" in text:
        text = text.partition("+")[0]
    prerelease = None
    if "-" in text:
        core, _, prerelease_text = text.partition("-")
        prerelease = prerelease_text.split(".") if prerelease_text else []
    else:
        core = text
    components = []
    wildcard_seen = False
    for part in core.split("."):
        if part in WILDCARDS:
            components.append(None)
            wildcard_seen = True
            continue
        if wildcard_seen or not part.isdigit():
            raise CheckError(f"invalid range version {text!r}")
        components.append(int(part))
    if not components or len(components) > 3:
        raise CheckError(f"invalid range version {text!r}")
    return components, prerelease


def term_matches(version_text, term):
    match = TERM_RE.match(term)
    if not match:
        raise CheckError(f"invalid range term {term!r}")
    operator = match.group(1) or "="
    components, prerelease = parse_range_version(match.group(2))
    first_wildcard = next(
        (index for index, part in enumerate(components) if part is None), None
    )
    specified = len(components) if first_wildcard is None else first_wildcard
    core = [part if part is not None else 0 for part in components]
    core = core + [0] * (3 - len(core))

    def bound(values, pre=None):
        return (values[0], values[1], values[2], pre)

    def upper_bound():
        values = list(core)
        if first_wildcard is not None:
            index = first_wildcard - 1
            if index < 0:
                return None
            values[index] += 1
            for position in range(index + 1, 3):
                values[position] = 0
            return bound(values, ["0"])
        if operator == "~":
            if specified >= 2:
                values[1] += 1
                values[2] = 0
            else:
                values[0] += 1
                values[1] = 0
                values[2] = 0
        elif operator == "^":
            if values[0] != 0:
                values[0] += 1
                values[1] = 0
                values[2] = 0
            elif specified >= 2 and values[1] != 0:
                values[1] += 1
                values[2] = 0
            elif specified >= 3 and values[2] != 0:
                values[2] += 1
            elif specified >= 2:
                values[1] += 1
                values[2] = 0
            else:
                values[0] += 1
                values[1] = 0
                values[2] = 0
        else:
            return None
        return bound(values, ["0"])

    lower = bound(core, prerelease)

    if operator in ("=", "~", "^"):
        if first_wildcard == 0:
            return True
        if operator == "=" and first_wildcard is None:
            return compare_versions(parse_version(version_text), lower) == 0
        upper = upper_bound()
        if upper is None:
            return True
        version = parse_version(version_text)
        return (
            compare_versions(version, lower) >= 0
            and compare_versions(version, upper) < 0
        )

    version = parse_version(version_text)
    if operator == ">=":
        return compare_versions(version, lower) >= 0
    if operator == ">":
        if first_wildcard not in (None, 0):
            return compare_versions(version, upper_bound()) >= 0
        return compare_versions(version, lower) > 0
    if operator == "<":
        return compare_versions(version, lower) < 0
    if operator == "<=":
        if first_wildcard not in (None, 0):
            return compare_versions(version, upper_bound()) < 0
        return compare_versions(version, lower) <= 0
    raise CheckError(f"unsupported operator {operator!r}")


def range_matches(version_text, ranges):
    candidates = ranges if isinstance(ranges, list) else [ranges]
    if not candidates:
        raise CheckError("empty dependency range")
    for candidate in candidates:
        if not isinstance(candidate, str):
            raise CheckError(f"invalid dependency range {candidate!r}")
        terms = candidate.split()
        if not terms:
            raise CheckError(f"invalid dependency range {candidate!r}")
        if all(term_matches(version_text, term) for term in terms):
            return True
    return False


def format_range(ranges):
    return ranges if isinstance(ranges, str) else json.dumps(ranges)


def download_and_verify(url, destination, hash_format, expected_hash):
    if not isinstance(hash_format, str) or hash_format.lower() not in HASHERS:
        raise CheckError(f"unsupported hash format {hash_format!r}")
    hasher = HASHERS[hash_format.lower()]()
    request = urllib.request.Request(
        url, headers={"User-Agent": "dotfiles-minecraft-dependency-check"}
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response, open(
            destination, "wb"
        ) as handle:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                handle.write(chunk)
                hasher.update(chunk)
    except (urllib.error.URLError, OSError) as error:
        raise CheckError(f"download failed for {url}: {error}") from error
    actual_hash = hasher.hexdigest()
    if actual_hash != expected_hash.lower():
        raise CheckError(
            f"hash mismatch for {url}: expected {hash_format}:{expected_hash}, got {actual_hash}"
        )


def read_mod_metadata(jar_path):
    try:
        with zipfile.ZipFile(jar_path) as archive:
            with archive.open("fabric.mod.json") as handle:
                metadata = json.load(handle)
    except (KeyError, ValueError, zipfile.BadZipFile, OSError) as error:
        raise CheckError(f"cannot read fabric.mod.json: {error}") from error
    mod_id = metadata.get("id")
    mod_version = metadata.get("version")
    depends = metadata.get("depends", {})
    if not isinstance(mod_id, str) or not mod_id:
        raise CheckError("fabric.mod.json has no id")
    if not isinstance(mod_version, str) or not mod_version:
        raise CheckError("fabric.mod.json has no version")
    if not isinstance(depends, dict):
        raise CheckError("fabric.mod.json depends is not an object")
    return mod_id, mod_version, depends


def loader_version(pack_directory, versions, loader):
    declared = versions.get(loader)
    if isinstance(declared, str):
        return declared
    if loader is None:
        return None
    minecraft = versions.get("minecraft")
    loaders_file = pack_directory.parent / "loaders.nix"
    if not loaders_file.is_file() or not isinstance(minecraft, str):
        return None
    try:
        text = loaders_file.read_text(encoding="utf-8")
    except OSError:
        return None
    block = re.search(rf"\b{re.escape(loader)}\s*=\s*\{{(.*?)\}}", text, re.DOTALL)
    if not block:
        return None
    entry = re.search(
        rf'"{re.escape(minecraft)}"\s*=\s*"([^"]+)"', block.group(1)
    )
    return entry.group(1) if entry else None


def check_pack(pack_directory, temporary_directory):
    problems = []
    skips = []
    pack_file = pack_directory / "pack.toml"
    if not pack_file.is_file():
        return [f"ERROR {pack_directory}: pack.toml not found"], skips, 0
    try:
        with open(pack_file, "rb") as handle:
            pack = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as error:
        return [f"ERROR {pack_file}: {error}"], skips, 0
    versions = pack.get("versions", {})
    if not isinstance(versions, dict):
        return [f"ERROR {pack_file}: versions section is not a table"], skips, 0
    minecraft_version = versions.get("minecraft")
    if not isinstance(minecraft_version, str):
        return [f"ERROR {pack_file}: missing minecraft version"], skips, 0
    loader = next(
        (name for name in LOADERS if isinstance(versions.get(name), str)), None
    )
    loader_version_value = loader_version(pack_directory, versions, loader)
    mods_directory = pack_directory / "mods"
    metafiles = (
        sorted(mods_directory.glob("*.pw.toml")) if mods_directory.is_dir() else []
    )
    mods = {}
    counter = 0
    for metafile in metafiles:
        counter += 1
        try:
            with open(metafile, "rb") as handle:
                data = tomllib.load(handle)
            download = data.get("download")
            if not isinstance(download, dict):
                raise CheckError("missing [download] section")
            url = download.get("url")
            hash_format = download.get("hash-format")
            expected_hash = download.get("hash")
            if (
                not isinstance(url, str)
                or not isinstance(hash_format, str)
                or not isinstance(expected_hash, str)
            ):
                raise CheckError("[download] needs url, hash-format and hash")
            filename = Path(urllib.parse.urlparse(url).path).name
            filename = urllib.parse.unquote(filename) or f"mod-{counter}.jar"
            destination = temporary_directory / f"{counter:03d}-{filename}"
            download_and_verify(url, destination, hash_format, expected_hash)
            mod_id, mod_version, depends = read_mod_metadata(destination)
        except (OSError, tomllib.TOMLDecodeError, CheckError) as error:
            problems.append(f"ERROR {metafile.relative_to(pack_directory)}: {error}")
            continue
        if mod_id in mods and mods[mod_id][0] != mod_version:
            problems.append(f"ERROR {metafile.name}: duplicate mod id {mod_id}")
            continue
        mods[mod_id] = (mod_version, depends)
    if any("java" in depends for _, depends in mods.values()):
        skips.append(
            "SKIP java dependencies (java version is provided by the launcher, not pinned in pack.toml)"
        )
    for mod_id in sorted(mods):
        _, depends = mods[mod_id]
        for dependency in sorted(depends):
            ranges = depends[dependency]
            if dependency == "java":
                continue
            if dependency == "minecraft":
                found = minecraft_version
            elif dependency == "fabricloader":
                if loader_version_value is None:
                    skips.append(
                        f"SKIP {mod_id} requires fabricloader {format_range(ranges)} (no loader version found in pack.toml or loaders.nix)"
                    )
                    continue
                found = loader_version_value
            elif dependency in mods:
                found = mods[dependency][0]
            else:
                skips.append(
                    f"SKIP {mod_id} requires {dependency} {format_range(ranges)} (not a mod in this pack)"
                )
                continue
            try:
                matched = range_matches(found, ranges)
            except CheckError as error:
                problems.append(
                    f"ERROR {mod_id} requires {dependency} {format_range(ranges)}: {error}"
                )
                continue
            if not matched:
                problems.append(
                    f"FAIL {mod_id} requires {dependency} {format_range(ranges)} but found {found}"
                )
    return problems, skips, len(mods)


def discover_pack_directories():
    repository_root = Path(__file__).resolve().parent.parent
    return sorted(path.parent for path in repository_root.glob("minecraft/*/pack.toml"))


def main(arguments):
    pack_directories = (
        [Path(argument) for argument in arguments]
        if arguments
        else discover_pack_directories()
    )
    if not pack_directories:
        print("No minecraft packs found")
        return 0
    temporary_directory = Path(tempfile.mkdtemp(prefix="check-minecraft-deps-"))
    problem_count = 0
    try:
        for pack_directory in pack_directories:
            problems, skips, mod_count = check_pack(pack_directory, temporary_directory)
            for line in skips:
                print(line)
            for line in problems:
                print(line)
            problem_count += len(problems)
            if problems:
                print(
                    f"FAIL {pack_directory} ({mod_count} mods, {len(problems)} problems)"
                )
            else:
                print(f"PASS {pack_directory} ({mod_count} mods checked)")
    finally:
        shutil.rmtree(temporary_directory, ignore_errors=True)
    if problem_count:
        print(f"RESULT FAIL ({problem_count} problems, {len(pack_directories)} packs)")
        return 1
    print(f"RESULT PASS ({len(pack_directories)} packs)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
