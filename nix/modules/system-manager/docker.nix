{ pkgs, ... }:

{
  environment = {
    systemPackages = [ pkgs.docker ];

    etc."docker/daemon.json".text = builtins.toJSON {
      "log-driver" = "json-file";
      "log-opts" = {
        "max-size" = "10m";
        "max-file" = "3";
      };
    };
  };

  users.groups.docker.members = [ "k0ch4nx" ];

  systemd = {
    services.docker = {
      enable = true;
      description = "Docker Application Container Engine";
      after = [
        "network-online.target"
        "docker.socket"
      ];
      wants = [ "network-online.target" ];
      requires = [ "docker.socket" ];
      wantedBy = [ "system-manager.target" ];
      startLimitBurst = 3;
      startLimitIntervalSec = 60;

      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.docker}/bin/dockerd --host=fd:// --config-file=/etc/docker/daemon.json";
        ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
        TimeoutStartSec = 0;
        RestartSec = 2;
        Restart = "always";
        LimitNOFILE = 1048576;
        LimitNPROC = "infinity";
        LimitCORE = "infinity";
        TasksMax = "infinity";
        Delegate = true;
        KillMode = "process";
        OOMScoreAdjust = -500;
      };
    };

    sockets.docker = {
      enable = true;
      description = "Docker Socket for the API";
      after = [ "userborn.service" ];
      requires = [ "userborn.service" ];
      wantedBy = [ "sockets.target" ];

      socketConfig = {
        ListenStream = "/run/docker.sock";
        SocketMode = "0660";
        SocketUser = "root";
        SocketGroup = "docker";
      };
    };

    tmpfiles.rules = [
      "d /var/lib/docker 0710 root root -"
      "d /run/docker 0755 root root -"
    ];
  };
}
