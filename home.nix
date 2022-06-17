{ config, pkgs, lib, ... }:
let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
{
  home.username = "jbuecker";
  home.homeDirectory = "/Users/jbuecker";
  home.stateVersion = "22.05";
  home.sessionVariables = {
    EDITOR = "lvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  home.packages = with pkgs; [ 
    tmux
    coreutils
    findutils
    ripgrep
    wget
    curl
    unzip
    zip
    htop
    jq
    pigz
    #awscli2
    unstable.ssm-session-manager-plugin
    golangci-lint
    php
    phpPackages.composer
    glab
    docker-compose
    gnupg
    unstable.temporal
    xsel
    fzf
    zsh
    oh-my-zsh
    bitwarden-cli
    git-crypt
    jpegoptim
    unrar
    direnv
    wireguard-tools
    wireguard-go
    neovim
    natscli
    nodejs
    dogdns
    bandwhich
    gping
    rm-improved
    tldr
    tfswitch
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  programs.bottom = {
      enable = true;
    };

  programs.go = {
    enable = true;
    package = unstable.go_1_18;
    goPrivate = [ "gitlab.shopware.com" ];
    goPath = "opt/go";
  };

  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
    };
    publicKeys = [{
      source = ./apps/gnupg/pubkey.pub;
      trust = "ultimate";
    }];
  };

  programs.git = {
    enable = true;
    package = unstable.git;

    signing.key = "C87088800768BC0E";
    signing.signByDefault = true;

    userEmail = "j.buecker@shopware.com";
    userName = "Jan Bücker";

    aliases = {
      rs = "restore --staged";
      amend = "commit --amend --reuse-message=HEAD";
    };

    extraConfig = {
      push.default = "simple";
      fetch.prune = true;
      init.defaultBranch = "main";
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
      plugins = ["git" "docker" "docker-compose" "aws"];
    };
    localVariables = {
      PATH = "$PATH:$GOPATH/bin:$HOME/.local/bin:$HOME/Library/Python/3.8/bin:$HOME/bin"; # fix for pip deps
    };
    sessionVariables = {
      DOCKER_BUILDKIT = 1;
    };
    shellAliases = {
      # pbcopy = "xsel --clipboard --input"; # linux only
      open = "xdg-open";
      adminer = "php -S 0.0.0.0:8080 $HOME/Downloads/adminer.php";
      ykrestart = "gpgconf --reload scdaemon && gpgconf --kill gpg-agent && gpg-connect-agent updatestartuptty /bye";
      awsume = ". awsume";
      # ssh = "TERM=xterm-256color ssh"; # required when using kitty
      hm = "home-manager";
      vi = "lvim";
      vim = "lvim";
      dig = "dog";
      ping = "gping";
      rm = "rip";
    };
    initExtra = ''
      # custom console theme
      source $HOME/.oh-my-zsh/custom/themes/honukai.zsh-theme

      # Yubikey setup
      export GIT_SSH="/usr/bin/ssh"
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent

      # custom scripts
      ${builtins.readFile ./apps/zsh/scripts.sh}
    '';
  };

  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrains Mono";
      size = 16;
    };
    extraConfig = ''
      mouse_map left click ungrabbed no-op
      mouse_map ctrl+left release grabbed,ungrabbed mouse_handle_click link

      map alt+left send_text all \x1b\x62
      map alt+right send_text all \x1b\x66

      # Move the active window in the indicated direction
      map shift+up move_window up
      map shift+left move_window left
      map shift+right move_window right
      map shift+down move_window down
      '';
  };

  home.file = {
    ".oh-my-zsh/custom/themes/honukai.zsh-theme".source = config.lib.file.mkOutOfStoreSymlink ./apps/oh-my-zsh/honukai.zsh-theme;
    ".config/alacritty/alacritty.yml".source = config.lib.file.mkOutOfStoreSymlink ./apps/alacritty/alacritty.yml;
    ".gnupg/pubkey.pub".source = config.lib.file.mkOutOfStoreSymlink ./apps/gnupg/pubkey.pub;
    ".gnupg/gpg-agent.conf".source = config.lib.file.mkOutOfStoreSymlink ./apps/gnupg/gpg-agent.conf;

# secrets
    ".aws/config".source = config.lib.file.mkOutOfStoreSymlink ./secrets/aws/config;
    ".aws/credentials".source = config.lib.file.mkOutOfStoreSymlink ./secrets/aws/credentials;
    ".ssh/cloud".source = config.lib.file.mkOutOfStoreSymlink ./secrets/ssh/cloud;
    ".ssh/config".source = config.lib.file.mkOutOfStoreSymlink ./secrets/ssh/config;
    ".netrc".source = config.lib.file.mkOutOfStoreSymlink ./secrets/netrc;
    ".config/wireguard/prod.private-key.gpg".source = config.lib.file.mkOutOfStoreSymlink ./secrets/wireguard/prod.private-key.gpg;
    ".config/wireguard/staging.private-key.gpg".source = config.lib.file.mkOutOfStoreSymlink ./secrets/wireguard/staging.private-key.gpg;
  };
}
