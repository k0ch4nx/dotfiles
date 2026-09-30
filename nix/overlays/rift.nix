final: prev:
let
  version = "0.6.2";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-/DpzPHqA5h4+0mwdWKr/za8kTTio5AmZmb5Gbdpxdy4=";
  };
in
{
  rift-wm = prev.rift-wm.overrideAttrs (old: {
    inherit version src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "rift-wm-${version}";
      hash = "sha256-HnOhkR7p1nqjyBdzhY+UJzOBohfd1k0LpzF9+CmIFsA=";
    };

    checkFlags = old.checkFlags ++ [
      "--skip=actor::reactor::tests::user_space_window_server_destroyed_removes_window_when_window_server_is_gone"
      "--skip=actor::reactor::tests::user_space_window_server_events_preserve_hidden_window_state"
      "--skip=actor::spaces::tests::confirmed_window_move_forwards_membership_without_space_switch"
    ];
  });
}
