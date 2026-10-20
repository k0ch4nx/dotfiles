{ config, pkgs, ... }:

let
  nvimDir = "${config.dotfiles.path}/nix/home/k0ch4nx/files/nvim";

  # codelldb ships its adapter inside the VS Code extension directory, so expose
  # the binary on PATH for nvim-dap.
  codelldb =
    pkgs.runCommandLocal "codelldb-${pkgs.vscode-extensions.vadimcn.vscode-lldb.version}"
      {
        meta.mainProgram = "codelldb";
      }
      ''
        mkdir -p $out/bin
        ln -s ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $out/bin/codelldb
      '';

  # nixpkgs does not package the Gradle language server yet.
  # https://github.com/microsoft/vscode-gradle
  gradle-language-server = pkgs.stdenvNoCC.mkDerivation {
    pname = "gradle-language-server";
    version = "3.17.3";

    src = pkgs.fetchurl {
      url = "https://open-vsx.org/api/vscjava/vscode-gradle/3.17.3/file/vscjava.vscode-gradle-3.17.3.vsix";
      hash = "sha256-fam1F9DNKMNFIqvyA4Ut4D9EuqLtx3bcUz67XD9WTFg=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/gradle-language-server $out/bin
      unzip -q "$src" -d $out/share/gradle-language-server

      cat > $out/bin/gradle-language-server <<EOF
      #!${pkgs.runtimeShell}
      exec ${pkgs.jre}/bin/java -jar $out/share/gradle-language-server/extension/lib/gradle-language-server.jar "\$@"
      EOF
      chmod +x $out/bin/gradle-language-server

      runHook postInstall
    '';

    meta.mainProgram = "gradle-language-server";
  };

  neovimTools = with pkgs; [
    go

    # LSP servers
    astro-language-server
    bash-language-server
    clang-tools
    docker-compose-language-service
    dockerfile-language-server
    gradle-language-server
    jdt-language-server
    lua-language-server
    nil
    oxfmt
    oxlint
    powershell
    powershell-editor-services
    pyrefly
    roslyn-ls
    ruff
    rust-analyzer
    sqls
    starpls
    svelte-language-server
    tailwindcss-language-server
    terraform-ls
    tombi
    typescript-language-server
    typos-lsp
    vscode-langservers-extracted
    vue-language-server
    yaml-language-server
    zls
    python3Packages.jedi-language-server

    # Formatters and linters
    buildifier
    checkstyle
    csharpier
    hadolint
    nixfmt
    npm-groovy-lint
    shellcheck
    shfmt
    sqruff
    statix
    terraform
    trivy
    yamlfmt
    yamllint

    # DAP
    codelldb
  ];
in
{
  programs.neovim = {
    enable = true;
    extraPackages = neovimTools;
  };

  xdg.configFile = {
    "nvim/.luarc.jsonc".source = ./files/nvim/.luarc.jsonc;
    "nvim/after".source = ./files/nvim/after;
    "nvim/init.lua".source = ./files/nvim/init.lua;
    "nvim/lazy-nvim".source = pkgs.vimPlugins.lazy-nvim;
    "nvim/lua".source = ./files/nvim/lua;
    "nvim/patches".source = ./files/nvim/patches;
    "nvim/lazy-lock.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${nvimDir}/lazy-lock.json";
      force = true;
    };
    # Store paths that the Lua configuration cannot express itself.
    "nvim/nix-paths.json".text = builtins.toJSON {
      codelldb = "${codelldb}/bin/codelldb";
      java_debug_dir = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";
      lombok_jar = "${pkgs.lombok}/share/java/lombok.jar";
      powershell_bundle = "${pkgs.powershell-editor-services}/lib/powershell-editor-services";
      vue_typescript_plugin = "${pkgs.vue-language-server}/lib/language-tools/packages/typescript-plugin";
    };
  };
}
