# dumb term config
if [[ "$TERM" == "dumb" ]]
then
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
# zstyle ':completion:*:matches'         group 'yes'
# zstyle ':completion:*'                 group-name ''
zstyle ':completion:*' menu select
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

# external utilities
yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" 
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

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
source <(fzf --zsh)

# start routine
clear
clear
