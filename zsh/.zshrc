# dumb term config
if [[ "$TERM" == "dumb" ]]; then
    unsetopt zle
    unsetopt prompt_cr
    unsetopt prompt_subst
    if whence -w precmd >/dev/null; then
        unfunction precmd
    fi
    if whence -w preexec >/dev/null; then
        unfunction preexec
    fi
    PS1='$ '
    return
fi

# macos or linux config difference
if [ -x "$(command -v dircolors)" ]; then
    eval "$(dircolors)"
fi

if [ -x "$(command -v gircolors)" ]; then
    eval "$(gdircolors)"
fi

if [[ -x "$(command -v brew)" && -d "$(brew --prefix)/share" ]]; then
    export ZSH_PLUGIN_DIR="$(brew --prefix)/share"
else
    export ZSH_PLUGIN_DIR="/usr/share/zsh/plugins"
fi

# completions
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' list-dirs-first true

fpath=($ZSH_PLUGIN_DIR/zsh-completions/src $fpath)
autoload -Uz compinit
compinit

setopt globdots

# starship
if [ ! $(tty | grep tty) ] && [ -x "$(command -v starship)" ]; then
    export STARSHIP_CONFIG=~/.config/starship/starship.toml
    eval "$(starship init zsh)"
    source $ZDOTDIR/starship-transient.zsh
fi

# default programs
if [ -x "$(command -v most)" ]; then
    export PAGER=most
fi

if [ -x "$(command -v helix)" ]; then
    export EDITOR=helix
    alias hx=helix
elif [ -x "$(command -v hx)"]; then
    export EDITOR=hx
fi

if [ -x "$(command -v ghostty)" ]; then
    export TERMINAL=ghostty
fi

# external utilities
if [ -x "$(command -v yazi)" ]; then
    yy() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" 
        yazi "$@" --cwd-file="$tmp"
        IFS= read -r -d '' cwd < "$tmp"
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
fi

if [ -x "$(command -v fzf)" ]; then
    source <(fzf --zsh)

    export FZF_COMPLETION_TRIGGER='**'

    export FZF_DEFAULT_OPTS=$'--style=minimal
      --padding=1
      --info=inline
      --border
      --color=fg:#abb2bf,bg:#282c34,hl:#c678dd,fg+:#ffffff,bg+:#4b5263
      --color=hl+:#e5c07b,info:#98c379,prompt:#61afef,pointer:#e06c75
      --color=marker:#d87c73,spinner:#61afef,header:#61afef,border:#5c6370
      --color=gutter:#4b5263'
    
    export FZF_COMPLETION_OPTS=$FZF_DEFAULT_OPTS
    source $ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh
    zstyle ':fzf-tab:*' use-fzf-default-opts yes
    zstyle ':fzf-tab:*' switch-group '<' '>'
      
    _fzf_complete_umu-run() {
      _fzf_complete -- "$@" < <(
          find ~/Games -name "*.exe" \
              ! -wholename "*/drive_c/*" \
              ! -wholename "*/umu/*" \
              ! -wholename "*/.utils/*" \
              ! -name "UnityCrashHandler64.exe"
      )
    }
fi

if [ -x "$(command -v umu-run)" ]; then
    umu-make() {
        local app=$1
        local type=${app#*.}

        if [[ $type != "exe" ]]; then;
            echo "error: invalid file type \"${type}\""
            return
        fi

        local abs_path=$(realpath "$app")
        local name=${${app:0:(-4)}##*/}

        if [[ ! ( -f $abs_path ) ]]; then
            echo "error: file does not exist"
            return
        fi

        local shortcut=$(realpath ~/.local/share/applications/"$name".desktop)

        if [[ -f $shortcut ]]; then
            echo "error: desktop file already exists"
            return
        fi

        local icon=$(realpath ~/.local/share/applications/icons/"$name".ico)
        icoextract $abs_path $icon

        cat << EOF > $shortcut
[Desktop Entry]
Categories=Games
Exec=umu-run ${abs_path}
Name=${name}
Type=Application
Icon=${icon}
EOF
    }
fi

# fg hotkey
zle_eval() {
    echo -en "\e[2K\r]"
    eval "$@"
    zle redisplay
}

zle_fg() { zle_eval fg }
zle -N zle_fg
bindkey "^z" zle_fg

# keybinds
bindkey "^[J" down-line-or-history
bindkey "^[K" up-line-or-history

# aliases
alias clear='repeat $LINES-2 echo'
alias ls='ls -A --group --color=always'
alias pac='doas pacman'
alias nosleep='kde-inhibit --power --screenSaver'

# pnpm
export PNPM_HOME="/home/cb/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# history
export HISTFILE=$ZDOTDIR/.zsh_history
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# auto suggestions
source $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(completion history)
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste up-line-or-search down-line-or-search expand-or-complete accept-line push-line-or-edit)

# highlighting
source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# start routine
clear
clear
