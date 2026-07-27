{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.pcsclite ];

  systemd = {
    maskedUnits = [
      "pcscd.service"
      "pcscd.socket"
    ];

    services.dotfiles-pcscd = {
      enable = true;
      description = "PC/SC Smart Card Daemon";
      after = [ "systemd-udevd.service" ];
      wantedBy = [ "system-manager.target" ];

      environment.PCSCLITE_HP_DROPDIR = "${pkgs.ccid}/pcsc/drivers";

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.pcsclite}/bin/pcscd -f -c /dev/null";
        RuntimeDirectory = "pcscd";
        RuntimeDirectoryMode = "0755";
        Restart = "on-failure";
      };
    };
  };
}
