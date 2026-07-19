{ ... }:

{
  nix = {
    gc = {
      automatic = true;
      interval = {
        Hour = 3;
        Minute = 15;
      };
      options = "--delete-older-than 1d";
    };

    settings = {
      keep-outputs = false;
      keep-derivations = false;
      auto-optimise-store = true;
    };
  };
}
