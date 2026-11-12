# Overlay updates design

Date: 2026-11-12

## Intent

Keep the dotfiles' package overlays current with upstream stable releases and identify overlays that can safely be retired, without losing local behavior.

## Goals

- Update Omni `0.19.12` → `0.20.2`, Rift `0.8.0` → `0.8.1`, and Plannotator `0.28.55` → `0.28.61`.
- Refresh source, vendoring, and platform binary hashes required by those releases.
- Check every overlay against its consumers and the repository's pinned Nixpkgs revision for safe removal.

## Non-goals

- Do not change the Nixpkgs pin or unrelated lock entries.
- Do not remove an overlay merely because a package with the same name exists in Nixpkgs.
- Do not update prereleases or moving upstream branches.
- Do not modify the original checkout's existing uncommitted changes.

## Approaches

1. **Update published stable releases and preserve overlays that still carry required behavior (chosen).** This updates the three newer stable releases and their hashes while retaining custom patches, forks, and dependency pins. It is reproducible and matches the project's current tag-based pins.
2. **Track prereleases/upstream heads and remove overlays whenever Nixpkgs has the package.** This is rejected: it weakens reproducibility, and Nixpkgs' Azahar, JankyBorders, and Rift packages do not include the local fixes/features or the required Rift version.

## Constraints and decisions

- The committed `flake.lock` pins Nixpkgs to `4fe25e12eb9f4c744966dd3de5a05246cf098601`; the existing worktree-only lock changes do not alter that pin.
- No full overlay can currently be removed. All overlay packages have active configuration consumers. Keep the Azahar Qt 6.12 include fix, JankyBorders fork feature, both Rift patches, and gamdl's compatibility dependency overrides.
- Perform the implementation in `.worktrees/overlay-updates`; leave the original checkout untouched. Do not push.

## Implementation outline

- Update the three selected version pins and recompute their Nix hashes. Preserve Rift's `regular-xpc-apps.patch`, `enter-fullscreen.patch`, and `doCheck = false`.
- Leave all other overlay definitions unchanged; record no removals unless new evidence appears during implementation.

## Verification

- Format and diff-check changed Nix files.
- Confirm the Rift patches apply to v0.8.1.
- Evaluate/build the affected package derivations and run `nix flake check --no-build --no-write-lock-file`.
- Review the final diff to confirm it contains only the three overlay updates plus this design document.
