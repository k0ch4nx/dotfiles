{ config, pkgs, ... }:

let
  nvimDir = "${config.dotfiles.path}/nix/home/k0ch4nx/files/nvim";

  codelldb =
    pkgs.runCommandLocal "codelldb-${pkgs.vscode-extensions.vadimcn.vscode-lldb.version}"
      {
        meta.mainProgram = "codelldb";
      }
      ''
        mkdir -p $out/bin
        ln -s ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $out/bin/codelldb
      '';

  neovimTools = with pkgs; [
    go

    astro-language-server
    bash-language-server
    clang-tools
    docker-compose-language-service
    dockerfile-language-server
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
    "nvim/nix-paths.json".text = builtins.toJSON {
      codelldb = "${codelldb}/bin/codelldb";
      java_debug_dir = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";
      lombok_jar = "${pkgs.lombok}/share/java/lombok.jar";
      powershell_bundle = "${pkgs.powershell-editor-services}/lib/powershell-editor-services";
      rust_analyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      typescript_tsdk = "${pkgs.typescript_5}/lib/node_modules/typescript/lib";
      vue_typescript_plugin = "${pkgs.vue-language-server}/lib/language-tools/packages/typescript-plugin";
    };
  };
}
