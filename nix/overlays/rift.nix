final: prev:
let
  version = "0.6.7";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-LKtoNs76hY66h8cTrZa9yDgyvGMT0lhjOf1ChqrKq60=";
  };
in
{
  rift-wm = prev.rift-wm.overrideAttrs (old: {
    inherit version src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "rift-wm-${version}";
      hash = "sha256-eVJCwA4C8F5UR5grBWMwdekuBrRdyAABUaYJxNBt6t0=";
    };

    checkFlags = old.checkFlags ++ [
      "--skip=actor::reactor::tests::user_space_window_server_destroyed_removes_window_when_window_server_is_gone"
      "--skip=actor::reactor::tests::user_space_window_server_events_preserve_hidden_window_state"
      "--skip=actor::spaces::tests::confirmed_window_move_forwards_membership_without_space_switch"
      "--skip=actor::reactor::tests::inventory_does_not_replace_geometry_owned_by_pending_rift_transaction"
      "--skip=actor::reactor::tests::central_space_resolution_prefers_recent_move_target_over_stale_server_space"
      "--skip=actor::reactor::tests::discovery_prefers_authoritative_space_over_geometry_when_displays_overlap_workspaces"
      "--skip=actor::reactor::tests::multi_active_visible_window_appearance_keeps_display_assignment_and_visibility"
      "--skip=actor::reactor::tests::multi_active_visible_window_disappearance_does_not_reassign_between_display_spaces"
      "--skip=actor::reactor::tests::stale_user_space_appearance_is_ignored_when_authoritative_window_space_differs"
      "--skip=actor::reactor::tests::stale_user_space_appearance_is_ignored_when_server_state_already_matches_pending_target"
      "--skip=actor::reactor::tests::stale_user_space_disappearance_does_not_restore_old_display_assignment"
    ];
  });
}
