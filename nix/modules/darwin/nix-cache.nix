{ config, lib, ... }:

let
  accountId = "CHANGE_ME";
  bucket = "dotfiles-nix-cache";
  r2Cache = "s3://${bucket}?endpoint=${accountId}.r2.cloudflarestorage.com&scheme=https&region=auto&profile=nix-r2-read";
in
{
  nix.settings = {
    substituters = lib.mkBefore [
      r2Cache
    ];

    trusted-public-keys = lib.mkBefore [
      # Add local and CI cache signing public keys after generation.
      # dotfiles-r2-local-1:<PUBLIC_KEY>
      # dotfiles-r2-ci-1:<PUBLIC_KEY>
    ];
  };

  # Keep the cache configuration resilient.