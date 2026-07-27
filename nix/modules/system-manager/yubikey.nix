{ pkgs, ... }:

let
  reloadUdevRules = pkgs.writeShellScript "reload-yubikey-udev-rules" ''
    ${pkgs.systemd}/bin/udevadm control --reload
    ${pkgs.systemd}/bin/udevadm trigger \
      --subsystem-match=hidraw \
      --action=change \
      --settle
  '';
in
{
  environment.etc."udev/rules.d/70-u2f.rules".source =
    "${pkgs.libfido2}/etc/udev/rules.d/70-u2f.rules";

  users.groups.plugdev.members = [ "k0ch4nx" ];

  systemd.services.yubikey-udev-rules = {
    enable = true;
    description = "Reload YubiKey udev rules";
    after = [ "systemd-udevd.service" ];
    wantedBy = [ "system-manager.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = reloadUdevRules;
      RemainAfterExit = true;
    };
  };
}
