zmodload zsh/parameter  # Needed to access jobstates variable for STARSHIP_JOBS_COUNT

# -----------------------------
# 
# The following is adapted from
# https://github.com/starship/starship/blob/93d62dc2fe1b13094b92052d755825c5e7edf2ef/src/init/starship.zsh
# 
# -----------------------------

zmodload zsh/parameter

# Defines a function `__starship_get_time` that sets the time since epoch in millis in STARSHIP_CAPTURED_TIME.
if [[ $ZSH_VERSION == ([1-4]*) ]]; then
    # ZSH <= 5; Does not have a built-in variable so we will rely on Starship's inbuilt time function.
    __transient_get_time() {
        TRANSIENT_CAPTURED_TIME=$(::STARSHIP:: time)
    }
else
    zmodload zsh/datetime
    zmodload zsh/mathfunc
    __transient_get_time() {
        (( TRANSIENT_CAPTURED_TIME = int(rint(EPOCHREALTIME * 1000)) ))
    }
fi

# The two functions below follow the naming convention `prompt_<theme>_<hook>`
# for compatibility with Zsh's prompt system. See
# https://github.com/zsh-users/zsh/blob/2876c25a28b8052d6683027998cc118fc9b50157/Functions/Prompts/promptinit#L155

# Runs before each new command line.
transient_precmd() {
    # Save the status, because subsequent commands in this function will change $?
    TRANSIENT_CMD_STATUS=$? TRANSIENT_PIPE_STATUS=(${pipestatus[@]})

    # Calculate duration if a command was executed
    if (( ${+TRANSIENT_START_TIME} )); then
        # If an arithmetic expression evaluates to 0, its exit status is 1:
        # "The return status is 0 if the arithmetic value of the expression is non-zero, 1 if it is zero, and 2 if an error occurred."
        # In rare cases, the subtraction below can result in an int 0 result (yes, really),
        # which would then kill the shell if 'set -e' is in effect.
        # We therefore have to assign the result outside the expression (using 'STARSHIP_DURATION=$((...))'),
        # because unlike '(())', '$(())' gets a return status of 0 even if the expression evaluates to int 0
        # (but it still surfaces a potential error, normally status 2, as status 1).
        __transient_get_time && TRANSIENT_DURATION=$(( TRANSIENT_CAPTURED_TIME - TRANSIENT_START_TIME ))
        unset TRANSIENT_START_TIME
        # Drop status and duration otherwise
    else
        unset TRANSIENT_DURATION TRANSIENT_CMD_STATUS TRANSIENT_PIPE_STATUS
    fi

    # Use length of jobstates array as number of jobs. Expansion fails inside
    # quotes so we set it here and then use the value later on.
    TRANSIENT_JOBS_COUNT=${#jobstates}
}

# Runs after the user submits the command line, but before it is executed and
# only if there's an actual command to run
transient_preexec() {
    __transient_get_time && TRANSIENT_START_TIME=$TRANSIENT_CAPTURED_TIME
}


# Add hook functions
autoload -Uz add-zsh-hook
add-zsh-hook precmd transient_precmd
add-zsh-hook preexec transient_preexec

# --------------------------
#
# End of adapted section
# 
# --------------------------

set-long-prompt() {
    unset TRANSIENT_PROFILE
    TRANSIENT_RPROFILE="--right"
    zle .reset-prompt 2>/dev/null
}

set-short-prompt() {
    # check if command is multi line
    {
        unfunction _al_f_
        functions[_al_f_]=$BUFFER
    } 2> /dev/null
    if (( $+functions[_al_f_] )); then
        TRANSIENT_PROFILE="--profile=short"
    else
        TRANSIENT_PROFILE="--profile=multi_short"
    fi

    TRANSIENT_RPROFILE="--profile=rshort"
    zle .reset-prompt 2>/dev/null
}

transient-accept-line() {
    if [[ $CONTEXT == start ]] && [[ $PROMPT != '%# ' ]];  then
        set-short-prompt
    fi

    zle .accept-line
}

add-zsh-hook precmd set-long-prompt

trap 'set-short-prompt; return 130' INT
zle -N accept-line transient-accept-line

setopt promptsubst
PROMPT='$(starship prompt ${TRANSIENT_PROFILE} --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="${TRANSIENT_CMD_STATUS:-}" --pipestatus="${TRANSIENT_PIPE_STATUS[*]:-}" --cmd-duration="${TRANSIENT_DURATION:-}" --jobs="$TRANSIENT_JOBS_COUNT")'
RPROMPT='$(starship prompt ${TRANSIENT_RPROFILE} --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="${TRANSIENT_CMD_STATUS:-}" --pipestatus="${TRANSIENT_PIPE_STATUS[*]:-}" --cmd-duration="${TRANSIENT_DURATION:-}" --jobs="$TRANSIENT_JOBS_COUNT")'
