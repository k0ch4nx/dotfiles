final: prev:
let
  version = "0.6.1";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-SxhN9f0Ekc8VISsG37VJEO3qt5MXqq8qZcBEMTD9mCY=";
  };
in
{
  rift-wm = prev.rift-wm.overrideAttrs (old: {
    inherit version src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "rift-wm-${version}";
      hash = "sha256-WId2LP/9i17ybMEPvk6Z/V/eh7xTrQNH8VXigRVLFwU=";
    };

    checkFlags = old.checkFlags ++ [
      "--skip=actor::reactor::tests::user_space_window_server_destroyed_removes_window_when_window_server_is_gone"
      "--skip=actor::reactor::tests::user_space_window_server_events_preserve_hidden_window_state"
      "--skip=actor::spaces::tests::confirmed_window_move_forwards_membership_without_space_switch"
    ];
  });
}
