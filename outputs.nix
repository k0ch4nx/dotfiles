inputs:
let
  cache = import ./nix/r2-cache.nix;

  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  blueprint = inputs.blueprint {
    inherit inputs;
    prefix = "nix/";
    inherit systems;

    nixpkgs = {
      config.allowUnfree = true;
      overlays = import ./nix/overlays;
    };
  };

  wslHomeConfiguration =
    blueprint.legacyPackages.x86_64-linux.homeConfigurations."k0ch4nx@ubuntu-wsl";

  flake-file-eval = import ./flake-file.nix { inherit inputs; };

  flake-file-apps = inputs.nixpkgs.lib.genAttrs systems (
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    builtins.mapAttrs (name: app: {
      type = "app";
      program = "${app pkgs}/bin/${name}";
    }) flake-file-eval.config.flake-file.apps
  );
in
blueprint
// {
  apps = (blueprint.apps or { }) // flake-file-apps;

  cacheSettings = cache;

  configurationBuilds = {
    macbook-pro.system = blueprint.darwinConfigurations.macbook-pro.config.system.build.toplevel;

    ubuntu-wsl = {
      system = blueprint.systemConfigs.ubuntu-wsl;
      home = wslHomeConfiguration.activationPackage;
    };
  };

  darwinConfigurations = blueprint.darwinConfigurations // {
    cache-bootstrap = inputs.nix-darwin.lib.darwinSystem {
      modules = [ ./nix/cache-bootstrap/darwin.nix ];
      specialArgs = {
        flake = inputs.self;
        inherit inputs;
        hostName = "macbook-pro";
      };
    };
  };

  systemConfigs = blueprint.systemConfigs // {
    cache-bootstrap = inputs.system-manager.lib.makeSystemConfig {
      modules = [ ./nix/cache-bootstrap/wsl.nix ];
      specialArgs = {
        flake = inputs.self;
        inherit inputs;
        hostName = "ubuntu-wsl";
      };
    };
  };

  homeConfigurations."k0ch4nx@ubuntu-wsl" = wslHomeConfiguration;
  legacyPackages = { };
}
