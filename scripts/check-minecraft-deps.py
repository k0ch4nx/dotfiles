import hashlib
import io
import itertools
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
MINIMAL_PRERELEASE = "MINIMAL"
LOADERS = ("fabric", "quilt", "neoforge", "forge")
RANGE_MODS = {"minecraft", "fabricloader"}
SEARCH_BUDGET = 50000
NEST_LIMIT = 4


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
    left_minimal = MINIMAL_PRERELEASE in left
    right_minimal = MINIMAL_PRERELEASE in right
    if left_minimal or right_minimal:
        if left_minimal and right_minimal:
            return 0
        return -1 if left_minimal else 1
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


def range_lower(components, prerelease):
    values = [part if part is not None else 0 for part in components]
    values = values + [0] * (3 - len(values))
    return (values[0], values[1], values[2], prerelease)


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
    version = parse_version(version_text)

    if operator == "=":
        if specified == 0:
            return True
        if first_wildcard is not None:
            return all(
                version[index] == components[index] for index in range(specified)
            )
        return compare_versions(version, range_lower(components, prerelease)) == 0

    if first_wildcard is not None and operator in (">=", ">", "<", "<="):
        raise CheckError(f"invalid range term {term!r}")

    lower = range_lower(components, prerelease)

    if operator in (">=", ">", "<", "<="):
        if operator == ">=":
            return compare_versions(version, lower) >= 0
        if operator == ">":
            return compare_versions(version, lower) > 0
        if operator == "<=":
            return compare_versions(version, lower) <= 0
        return compare_versions(version, lower) < 0

    if operator == "^":
        major = components[0] if components and components[0] is not None else None
        if major is None:
            return True
        upper = (major + 1, 0, 0, (MINIMAL_PRERELEASE,))
        return (
            compare_versions(version, lower) >= 0
            and compare_versions(version, upper) < 0
        )

    if operator == "~":
        major = components[0] if components and components[0] is not None else None
        if major is None:
            return True
        minor = components[1] if specified >= 2 and components[1] is not None else 0
        upper = (major, minor + 1, 0, (MINIMAL_PRERELEASE,))
        return (
            compare_versions(version, lower) >= 0
            and compare_versions(version, upper) < 0
        )

    raise CheckError(f"unsupported operator {operator!r}")


def range_matches(version_text, ranges):
    candidates = ranges if isinstance(ranges, list) else [ranges]
    if not candidates:
        raise CheckError("empty dependency range")
    groups = []
    for candidate in candidates:
        if not isinstance(candidate, str):
            raise CheckError(f"invalid dependency range {candidate!r}")
        terms = candidate.split()
        if not terms:
            raise CheckError(f"invalid dependency range {candidate!r}")
        groups.append(terms)
    return any(
        all(term_matches(version_text, term) for term in terms) for terms in groups
    )


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


def provides_field(value):
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [entry for entry in value if isinstance(entry, str) and entry]
    return []


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
    breaks = metadata.get("breaks", {})
    recommends = metadata.get("recommends", {})
    suggests = metadata.get("suggests", {})
    provides = provides_field(metadata.get("provides"))
    if not isinstance(mod_id, str) or not mod_id:
        raise CheckError("fabric.mod.json has no id")
    if not isinstance(mod_version, str) or not mod_version:
        raise CheckError("fabric.mod.json has no version")
    if not isinstance(depends, dict):
        raise CheckError("fabric.mod.json depends is not an object")
    if not isinstance(breaks, dict):
        raise CheckError("fabric.mod.json breaks is not an object")
    if not isinstance(recommends, dict):
        raise CheckError("fabric.mod.json recommends is not an object")
    if not isinstance(suggests, dict):
        raise CheckError("fabric.mod.json suggests is not an object")
    return mod_id, mod_version, depends, breaks, recommends, suggests, provides


def read_metadata(payload):
    metadata = json.loads(payload)
    if not isinstance(metadata, dict):
        raise ValueError("fabric.mod.json is not an object")
    return metadata


def read_jar_metadata(payload):
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        return read_metadata(archive.read("fabric.mod.json"))


def declared_nested_paths(metadata):
    declared = metadata.get("jars")
    if not isinstance(declared, list):
        return []
    paths = []
    for entry in declared:
        if isinstance(entry, str):
            paths.append(entry)
        elif isinstance(entry, dict) and isinstance(entry.get("file"), str):
            paths.append(entry["file"])
    return paths


def metadata_section(metadata, key):
    value = metadata.get(key)
    return value if isinstance(value, dict) else {}


def collect_nested(archive, depth, entries):
    if depth > NEST_LIMIT:
        return
    try:
        metadata = read_metadata(archive.read("fabric.mod.json"))
    except (KeyError, ValueError, zipfile.BadZipFile, OSError):
        return
    for path in declared_nested_paths(metadata):
        try:
            payload = archive.read(path)
            nested_metadata = read_jar_metadata(payload)
        except (KeyError, ValueError, zipfile.BadZipFile, OSError):
            continue
        nested_id = nested_metadata.get("id")
        nested_version = nested_metadata.get("version")
        if (
            isinstance(nested_id, str)
            and nested_id
            and isinstance(nested_version, str)
            and nested_version
        ):
            entries.append(
                (
                    nested_id,
                    nested_version,
                    provides_field(nested_metadata.get("provides")),
                    metadata_section(nested_metadata, "depends"),
                    metadata_section(nested_metadata, "breaks"),
                )
            )
        with zipfile.ZipFile(io.BytesIO(payload)) as inner:
            collect_nested(inner, depth + 1, entries)


def read_nested_metadata(jar_path):
    entries = []
    try:
        with zipfile.ZipFile(jar_path) as archive:
            collect_nested(archive, 0, entries)
    except (zipfile.BadZipFile, OSError):
        pass
    return entries


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
    candidates = {}
    nested_mods = []
    seen_nested = set()
    counter = 0

    def add_candidate(mod_id, mod_version):
        existing = candidates.setdefault(mod_id, [])
        if mod_version not in existing:
            existing.append(mod_version)

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
            (
                mod_id,
                mod_version,
                depends,
                breaks,
                recommends,
                suggests,
                provides,
            ) = read_mod_metadata(destination)
            nested_entries = read_nested_metadata(destination)
        except (OSError, tomllib.TOMLDecodeError, CheckError) as error:
            problems.append(f"ERROR {metafile.relative_to(pack_directory)}: {error}")
            continue
        if mod_id in mods and mods[mod_id]["version"] != mod_version:
            problems.append(f"ERROR {metafile.name}: duplicate mod id {mod_id}")
            continue
        mods[mod_id] = {
            "version": mod_version,
            "depends": depends,
            "breaks": breaks,
            "recommends": recommends,
            "suggests": suggests,
        }
        add_candidate(mod_id, mod_version)
        for provided in provides:
            add_candidate(provided, mod_version)
        for (
            nested_id,
            nested_version,
            nested_provides,
            nested_depends,
            nested_breaks,
        ) in nested_entries:
            add_candidate(nested_id, nested_version)
            for provided in nested_provides:
                add_candidate(provided, nested_version)
            identity = (
                nested_id,
                nested_version,
                json.dumps(nested_depends, sort_keys=True),
                json.dumps(nested_breaks, sort_keys=True),
            )
            if identity in seen_nested:
                continue
            seen_nested.add(identity)
            nested_mods.append(
                (nested_id, nested_version, nested_depends, nested_breaks)
            )
    if any("java" in entry["depends"] for entry in mods.values()):
        skips.append(
            "SKIP java dependencies (java version is provided by the launcher, not pinned in pack.toml)"
        )

    range_cache = {}

    def matches(version, ranges):
        key = (version, json.dumps(ranges, sort_keys=True))
        cached = range_cache.get(key)
        if cached is None:
            try:
                cached = range_matches(version, ranges)
            except CheckError as error:
                cached = error
            range_cache[key] = cached
        if isinstance(cached, CheckError):
            raise cached
        return cached

    def evaluate(selection):
        found = []
        found_skips = []

        def present(dependency):
            if dependency == "minecraft":
                return [minecraft_version]
            if dependency == "fabricloader":
                return None if loader_version_value is None else [loader_version_value]
            if dependency in selection:
                return [selection[dependency]]
            return []

        def resolve(mod_id, dependency, ranges, required):
            versions_present = present(dependency)
            if versions_present is None:
                found_skips.append(
                    f"SKIP {mod_id} requires {dependency} {format_range(ranges)} (no loader version found in pack.toml or loaders.nix)"
                )
                return
            verb = "requires" if required else "optionally uses"
            sink = "failure" if required else "info"
            target = found if required else found_skips
            badge = "FAIL" if required else "SKIP"
            if not versions_present:
                target.append(
                    f"{badge} {mod_id} {verb} {dependency} {format_range(ranges)} "
                    f"but no mod in the pack provides {dependency} ({sink})"
                )
                return
            try:
                matched = [
                    version for version in versions_present if matches(version, ranges)
                ]
            except CheckError as error:
                target.append(
                    f"{badge} {mod_id} {verb} {dependency} {format_range(ranges)}: {error}"
                )
                return
            if not matched:
                target.append(
                    f"{badge} {mod_id} {verb} {dependency} {format_range(ranges)} "
                    f"but found {', '.join(sorted(versions_present))}"
                )

        def check_break(mod_id, target_id, ranges):
            versions_present = present(target_id)
            if not versions_present:
                return
            try:
                matched = [
                    version for version in versions_present if matches(version, ranges)
                ]
            except CheckError as error:
                found.append(
                    f"ERROR {mod_id} breaks {target_id} {format_range(ranges)}: {error}"
                )
                return
            if matched:
                found.append(
                    f"FAIL {mod_id} breaks {target_id} {format_range(ranges)} "
                    f"but {target_id} {', '.join(sorted(matched))} is present"
                )

        def inspect(mod_id, depends, breaks, optional):
            for dependency in sorted(depends):
                if dependency == "java":
                    continue
                resolve(mod_id, dependency, depends[dependency], True)
            for category in ("recommends", "suggests"):
                for dependency in sorted(optional.get(category, {})):
                    if dependency in ("java",) + tuple(RANGE_MODS):
                        continue
                    resolve(
                        mod_id, dependency, optional[category][dependency], False
                    )
            for target in sorted(breaks):
                if target == "java":
                    continue
                check_break(mod_id, target, breaks[target])

        for mod_id in sorted(mods):
            entry = mods[mod_id]
            inspect(mod_id, entry["depends"], entry["breaks"], entry)
        for nested_id, nested_version, nested_depends, nested_breaks in nested_mods:
            if selection.get(nested_id) != nested_version:
                continue
            inspect(nested_id, nested_depends, nested_breaks, {})
        return found, found_skips

    def report(selection):
        found, found_skips = evaluate(selection)
        for line in found_skips:
            if line not in skips:
                skips.append(line)
        return found

    fixed = {
        mod_id: versions[0]
        for mod_id, versions in candidates.items()
        if len(versions) == 1
    }
    variable = [
        mod_id for mod_id in sorted(candidates) if len(candidates[mod_id]) > 1
    ]
    selection = dict(fixed)
    if not variable:
        problems.extend(report(selection))
    else:
        found_selection = None
        fewest = None
        attempts = 0
        for combination in itertools.product(
            *[candidates[mod_id] for mod_id in variable]
        ):
            attempts += 1
            if attempts > SEARCH_BUDGET:
                break
            candidate_selection = dict(fixed)
            candidate_selection.update(zip(variable, combination))
            found = report(candidate_selection)
            if not found:
                found_selection = candidate_selection
                break
            if fewest is None or len(found) < len(fewest):
                fewest = found
        if found_selection is None:
            problems.append(
                "FAIL no consistent version selection exists for "
                + ", ".join(f"{mod_id} ({'/'.join(candidates[mod_id])})" for mod_id in variable)
            )
            if fewest is not None:
                problems.extend(sorted(set(fewest)))
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
