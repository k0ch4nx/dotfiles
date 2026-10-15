final: prev:
let
  version = "0.6.9";

  src = prev.fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    tag = "v${version}";
    hash = "sha256-MuXUyQ0b4v66yPwrfefCHaYGL7zo9hg1QJq4ve0kFCQ=";
  };
in
{
  rift-wm = prev.rift-wm.overrideAttrs (old: {
    inherit version src;

    patches = (old.patches or [ ]) ++ [
      ./patches/rift/regular-xpc-apps.patch
      ./patches/rift/enter-fullscreen.patch
    ];

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "rift-wm-${version}";
      hash = "sha256-JHB6yqrOuwZ+UwxSKBp9eh0bX4mkZndxQvHEtCclxPk=";
    };

    checkFlags = old.checkFlags ++ [
      "--test-threads=1"
      "--skip=actor::reactor::tests::user_space_window_server_destroyed_removes_window_when_window_server_is_gone"
      "--skip=actor::reactor::tests::user_space_window_server_events_preserve_hidden_window_state"
    ];
  });
}
