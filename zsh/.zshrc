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

fpath=(/usr/share/zsh/plugins/zsh-completions/src $fpath)
autoload -U compinit; compinit
_comp_options+=(globdots)

zle_eval() {
    echo -en "\e[2K\r]"
    eval "$@"
    zle redisplay
}

zle_fg() {
    zle_eval fg
}

yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" 
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

export STARSHIP_CONFIG=~/.config/starship/starship.toml

if [ ! $(tty | grep tty) ]; then
    eval "$(starship init zsh)"
    source $ZDOTDIR/starship-transient.zsh
fi

zle -N zle_fg

bindkey "^z" zle_fg
bindkey "^[J" down-line-or-history
bindkey "^[K" up-line-or-history

alias clear='repeat $LINES-2 echo'
alias ls='ls -A --group --color=always'

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# pnpm
export PNPM_HOME="/home/cb/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

clear
