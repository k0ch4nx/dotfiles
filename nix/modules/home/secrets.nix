{
  inputs,
  ...
}:

let
  cache = import ../../r2-cache.nix;
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  home.sessionVariables = {
    CLOUDFLARE_ACCOUNT_ID = cache.accountId;
    R2_CACHE_BUCKET = cache.bucket;
  };
}
