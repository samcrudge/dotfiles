{ config, pkgs, lib, ... }:
let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
  php = pkgs.php83.buildEnv {
    extraConfig = "memory_limit = 4G";
    extensions = ({ enabled, all }: enabled ++ (with all; [ redis grpc ]));
  };
  phpPackages = pkgs.php83.packages;

  terragrunt = pkgs.stdenv.mkDerivation {
    name = "terragrunt";
    phases = [ "installPhase" ];
    installPhase = ''
      install -D $src $out/bin/terragrunt
    '';
    src = pkgs.fetchurl {
      name = "terragrunt";
      url =
        "https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.3/terragrunt_darwin_arm64";
      sha256 = "1db45dyfbcii7jmh9whgf9dwffm562zw32afr5awp74gm7lkj5wz";
    };
  };

  golangci-lint-version = "1.57.1";
  golangci-lint = pkgs.stdenv.mkDerivation {
    name = "golangci-lint";
    phases = [ "installPhase" ];
    installPhase = ''
      install -D $src/golangci-lint $out/bin/golangci-lint
    '';
    src = pkgs.fetchzip {
      name = "golangci-lint";
      url =
        "https://github.com/golangci/golangci-lint/releases/download/v${golangci-lint-version}/golangci-lint-${golangci-lint-version}-darwin-arm64.tar.gz";
      sha256 = "0yk68nlwb34spscygmwvmp2k30cajmcd9wvvhxqflqa0v5j0cgjv";
    };
  };
in {
  home.username = "sam";
  home.homeDirectory = "/Users/sam";
  home.stateVersion = "23.11";
  home.sessionVariables = { EDITOR = "nvim"; };
  manual.manpages.enable = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # configure home paths
  xdg.enable = true;

  # neovim nightly
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];

  home.packages = with pkgs; [
    # unstable.neovim-unwrapped
    act
    bandwhich
    bash
    bat
    caddy
    cargo
    coreutils
    direnv
    docker
    fd
    findutils
    fzf
    git-crypt
    glab
    gnugrep
    gnused
    golangci-lint
    hclfmt
    htop
    jq
    k9s
    kubectl
    lazygit
    mysql80
    neovim-nightly
    nixfmt
    nodejs
    p7zip
    php
    php.packages.composer
    php.packages.php-cs-fixer
    php.packages.phpstan
    php.packages.psalm
    pigz
    postgresql
    ripgrep
    temporal-cli
    terraform
    terragrunt
    tldr
    tmux
    unrar
    unstable._1password
    unstable.awscli2
    unstable.cloudflared
    unstable.curl
    unstable.ssm-session-manager-plugin
    unzip
    wget
    wireguard-go
    wireguard-tools
    yamlfmt
    zip
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.eza = { enable = true; };
  programs.bottom = { enable = true; };

  programs.go = {
    enable = true;
    package = unstable.go_1_22;
    goPrivate = [ "gitlab.shopware.com" ];
    goPath = "opt/go";
  };

  programs.git = {
    enable = true;

    signing.key =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBEifC1XsdicwjoNw/zCfOJvazsl2Qjptnev377sh6J s.crudge@shopware.com";
    signing.signByDefault = true;

    userEmail = "s.crudge@shopware.com";
    userName = "Sam Crudge";

    aliases = {
      rs = "restore --staged";
      amend = "commit --amend --reuse-message=HEAD";
    };

    extraConfig = {
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.default = "simple";
      fetch.prune = true;
      init.defaultBranch = "main";
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };
    };

    ignores = [
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"

      "._*"

      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    oh-my-zsh = {
      enable = true;
      theme = "amuse";
      plugins = [ "git" "docker" "aws" "fzf" ];
    };
    localVariables = {
      PATH = builtins.concatStringsSep ":" [
        "$PATH"
        "$HOME/bin"
        "/usr/local/bin"
        "$GOPATH/bin"
        "$HOME/.local/bin"
        "${pkgs.nodejs}/bin"
        "/Applications/WezTerm.app/Contents/MacOS"
      ];
    };
    sessionVariables = {
      DOCKER_BUILDKIT = 1;
      MANPAGER = "nvim +Man!";
      AWS_PAGER = "";
      TF_PLUGIN_CACHE_DIR = "$HOME/.cache/terraform";
    };
    shellAliases = {
      hm = "home-manager";
      tmux = "tmux -u";
      lg = "lazygit";
      cat = "bat -pp";
      catt = "bat";
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
      fdd =
        "fd --type directory --search-path `git rev-parse --show-toplevel` | fzf";
      awslocal = "aws --endpoint-url http://localhost:4566";
      sso = "aws sso login --sso-session sso";
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      golangci-update =
        "${config.home.homeDirectory}/.nix-profile/bin/curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(${config.home.homeDirectory}/.nix-profile/bin/go env GOPATH)/bin";
      mclidev =
        "go build -C ~/opt/cloud/mcli -o mcli main.go && ~/opt/cloud/mcli/mcli --auto-update=false";
    };
    initExtra = ''
      # 1password
      eval "$(op completion zsh)"; compdef _op op
    '';
  };
  home.file = {
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink ./apps/nvim;
  };
}

