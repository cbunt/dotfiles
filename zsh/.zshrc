export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

_comp_options+=(globdots)

alias ls="ls -A --group --color=always"