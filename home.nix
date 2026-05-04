{ pkgs, ... }:
{
  home.stateVersion = "25.05";

  # GIT
  programs.git = {
    enable = true;
    settings = {
      user.name = "JettChenT";
      user.email = "jettchen12345@gmail.com";
      alias = {
        co = "checkout";
        cm = "commit";
        st = "status";
        br = "branch";
        df = "diff";
        lg = "log";
        pl = "pull";
      };
    };
  };

  # FISH
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings
      fish_add_path ~/.opencode/bin
      fish_add_path ~/.bun/bin
      fish_add_path ~/.cargo/bin
      fish_add_path ~/.local/bin
      fish_add_path ~/go/bin
      fish_add_path ~/.go/bin
      fish_add_path /opt/homebrew/bin

      # creds: https://github.com/ryanccn/flake
      function expose_app_to_path
          set -f app $argv[1]

          if test -d "$HOME/Applications/$app.app"
              fish_add_path -P "$HOME/Applications/$app.app/Contents/MacOS"
          end
          if test -d "/Applications/$app.app"
              fish_add_path -P "/Applications/$app.app/Contents/MacOS"
          end
      end

      expose_app_to_path Ghostty

      # cmux shell integration for fish
      # Detects cmux env vars and reports CWD, git branch, TTY, and ports
      # to the sidebar via the cmux unix socket.
      if set -q CMUX_SOCKET_PATH; and test -S "$CMUX_SOCKET_PATH"
          set -g _CMUX_PWD_LAST_PWD ""
          set -g _CMUX_GIT_LAST_PWD ""
          set -g _CMUX_GIT_LAST_RUN 0
          set -g _CMUX_GIT_FORCE 0
          set -g _CMUX_PORTS_LAST_RUN 0
          set -g _CMUX_CMD_START 0
          set -g _CMUX_TTY_NAME ""
          set -g _CMUX_TTY_REPORTED 0

          function _cmux_send
              set -l payload $argv[1]
              if command -q ncat
                  printf '%s\n' $payload | ncat -U "$CMUX_SOCKET_PATH" --send-only 2>/dev/null
              else if command -q socat
                  printf '%s\n' $payload | socat - "UNIX-CONNECT:$CMUX_SOCKET_PATH" 2>/dev/null
              else if command -q nc
                  printf '%s\n' $payload | nc -N -U "$CMUX_SOCKET_PATH" 2>/dev/null
                  or printf '%s\n' $payload | nc -w 1 -U "$CMUX_SOCKET_PATH" 2>/dev/null
                  or true
              end
          end

          function _cmux_resolve_tty
              if test -z "$_CMUX_TTY_NAME"
                  set -l t (tty 2>/dev/null; or true)
                  if test -n "$t"; and test "$t" != "not a tty"
                      set -g _CMUX_TTY_NAME (string replace -r '.*/+' "" -- "$t")
                  end
              end
          end

          function _cmux_report_tty_once
              test "$_CMUX_TTY_REPORTED" = 1; and return 0
              test -S "$CMUX_SOCKET_PATH"; or return 0
              test -n "$CMUX_TAB_ID"; or return 0
              test -n "$CMUX_PANEL_ID"; or return 0
              test -n "$_CMUX_TTY_NAME"; or return 0
              set -g _CMUX_TTY_REPORTED 1
              _cmux_send "report_tty $_CMUX_TTY_NAME --tab=$CMUX_TAB_ID --panel=$CMUX_PANEL_ID" &
              disown 2>/dev/null
          end

          function _cmux_ports_kick
              test -S "$CMUX_SOCKET_PATH"; or return 0
              test -n "$CMUX_TAB_ID"; or return 0
              test -n "$CMUX_PANEL_ID"; or return 0
              set -g _CMUX_PORTS_LAST_RUN (date +%s)
              _cmux_send "ports_kick --tab=$CMUX_TAB_ID --panel=$CMUX_PANEL_ID" &
              disown 2>/dev/null
          end

          function _cmux_preexec --on-event fish_preexec
              _cmux_resolve_tty
              set -g _CMUX_CMD_START (date +%s)
              set -l cmd (string trim -- $argv[1])
              if string match -q 'git *' -- "$cmd"; or test "$cmd" = git
                  set -g _CMUX_GIT_FORCE 1
              end
              _cmux_report_tty_once
              _cmux_ports_kick
          end

          function _cmux_precmd --on-event fish_prompt
              test -S "$CMUX_SOCKET_PATH"; or return 0
              test -n "$CMUX_TAB_ID"; or return 0
              test -n "$CMUX_PANEL_ID"; or return 0

              _cmux_resolve_tty
              _cmux_report_tty_once

              set -l now (date +%s)
              set -l pwd_val "$PWD"
              set -l cmd_start "$_CMUX_CMD_START"
              set -g _CMUX_CMD_START 0

              # CWD
              if test "$pwd_val" != "$_CMUX_PWD_LAST_PWD"
                  set -g _CMUX_PWD_LAST_PWD "$pwd_val"
                  set -l qpwd (string replace -a '"' '\\"' -- "$pwd_val")
                  _cmux_send "report_pwd \"$qpwd\" --tab=$CMUX_TAB_ID --panel=$CMUX_PANEL_ID" &
                  disown 2>/dev/null
              end

              # Git branch/dirty
              set -l should_git 0
              if test "$pwd_val" != "$_CMUX_GIT_LAST_PWD"
                  set should_git 1
              else if test "$_CMUX_GIT_FORCE" = 1
                  set should_git 1
              else if test (math "$now - $_CMUX_GIT_LAST_RUN") -ge 3
                  set should_git 1
              end

              if test "$should_git" = 1
                  set -g _CMUX_GIT_FORCE 0
                  set -g _CMUX_GIT_LAST_PWD "$pwd_val"
                  set -g _CMUX_GIT_LAST_RUN $now
                  begin
                      set -l branch (git branch --show-current 2>/dev/null)
                      if test -n "$branch"
                          set -l dirty_opt ""
                          set -l first (git status --porcelain -uno 2>/dev/null | head -1)
                          if test -n "$first"
                              set dirty_opt "--status=dirty"
                          end
                          _cmux_send "report_git_branch $branch $dirty_opt --tab=$CMUX_TAB_ID"
                      else
                          _cmux_send "clear_git_branch --tab=$CMUX_TAB_ID"
                      end
                  end &
                  disown 2>/dev/null
              end

              # Ports
              set -l cmd_dur 0
              if test -n "$cmd_start"; and test "$cmd_start" != 0
                  set cmd_dur (math "$now - $cmd_start")
              end
              if test "$cmd_dur" -ge 2; or test (math "$now - $_CMUX_PORTS_LAST_RUN") -ge 10
                  _cmux_ports_kick
              end
          end

          # Ensure Resources/bin is at the front of PATH for cmux claude wrapper.
          if set -q GHOSTTY_BIN_DIR; and test -n "$GHOSTTY_BIN_DIR"
              set -l bin_dir (string replace -r '/MacOS$' "" -- "$GHOSTTY_BIN_DIR")
              set bin_dir "$bin_dir/Resources/bin"
              if test -d "$bin_dir"
                  if set -l idx (contains -i -- "$bin_dir" $PATH)
                      set -e PATH[$idx]
                  end
                  set -gx PATH "$bin_dir" $PATH
              end
          end
      end

      # worktrunk shell integration
      function wt
          set -l use_source false
          set -l args

          for arg in $argv
              if test "$arg" = "--source"; set use_source true; else; set -a args $arg; end
          end

          test -n "$WORKTRUNK_BIN"; or set -l WORKTRUNK_BIN (type -P wt 2>/dev/null)
          if test -z "$WORKTRUNK_BIN"
              echo "wt: command not found" >&2
              return 127
          end
          set -l directive_file (mktemp)

          if test $use_source = true
              env WORKTRUNK_DIRECTIVE_FILE=$directive_file cargo run --bin wt --quiet -- $args
          else
              env WORKTRUNK_DIRECTIVE_FILE=$directive_file $WORKTRUNK_BIN $args
          end
          set -l exit_code $status

          if test -s "$directive_file"
              eval (cat "$directive_file" | string collect)
              if test $exit_code -eq 0
                  set exit_code $status
              end
          end

          rm -f "$directive_file"
          return $exit_code
      end
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
    ];
    shellAliases = {
      j = "just";
      klocal = "kubectl config use-context orbstack";
    };
    shellAbbrs = {
      gp = "git push";
      gpl = "git pull";
    };
  };

  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      shell.disabled = false;
      aws.disabled = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
    };
  };

  # NEOVIM
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = ''
      " Enable syntax highlighting
      syntax on

      " Line numbers
      set number
      set relativenumber
    '';
  };

  home.packages = with pkgs; [
    # Add any additional packages you want installed via home-manager
  ];
}
