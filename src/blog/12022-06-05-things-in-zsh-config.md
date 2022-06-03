# things in my zsh config

## dot dot dot

### _zsh_ config

Some of us lug around giant config files that improve our quality of life,
Here are some things I stuffed in mine:

#### _aliases_

##### _pyramid_ of dots

mash dots until you get to the right level,
though I don't usually go above 5 (or I get it wrong).
Along with `setopt AUTOCD` this helps navigation a lot.

```zsh
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias ........='cd ../../../../../../..'
alias .........='cd ../../../../../../../..'
alias ..........='cd ../../../../../../../../..'
alias ...........='cd ../../../../../../../../../..'
alias ............='cd ../../../../../../../../../../..'
```

##### go to repo root

Sometimes you just want to go back to the top

```zsh
alias rr='cd $(git rev-parse --show-toplevel)'
```

##### common tools

There are just some things I use a lot.

```zsh
alias cp='cp -v'
alias ln='ln -v'
alias mv='mv -v'
alias g='git'
alias h='htop'
alias k='kubectl'
alias s='ssh'
alias tf='terraform'
alias v='${EDITOR}'
```

##### better ls

I want a better ls with [exa](https://the.exa.website/),
but I don't want my config to break every time I clone it onto a new machine.

```
(( $+commands[exa] )) \
    && alias ll='exa -l -a --git --time-style iso --group-directories-first' \
    || alias ll='ls -alh';
```

#### _functions_

##### mkdir and cd

really simple and common thing

```zsh
function md() {
    [[ -z ${1// } ]] && echo "no directory name given" && return 1
    mkdir -p "$1" && cd "$1"
}
```

##### t

wrapper for [t](https://github.com/seankhliao/t),
population numbered aliases from the results of `ripgrep`

```zsh
function t() {
    command t -i "$@"
    source /tmp/t_aliases 2>/dev/null
}
```

##### testrepo

creates a temporary unique repo with an autoincrementing number

```zsh
function testrepo() {
    local vers=$(( $(cat ${XDG_CONFIG_HOME}/testrepo-version)+1))
    echo ${vers} > ${XDG_CONFIG_HOME}/testrepo-version
    mkdir -p ${HOME}/tmp
    cd ${HOME}/tmp
    mr testrepo-${vers}
}

function mr() {
    local repo=${1// }
    [[ -z ${repo} ]] && echo "no repo name given" && return 1
    mkdir -p ${repo}
    cd ${repo}
    git init
    git commit --allow-empty -m "root-commit"
    git remote add origin s:${repo}
}
```

#### _zle_

double tap ESC to get the previous command with sudo in front toggled

```zsh
zle -N _sudo_cmdline

function _sudo_cmdline() {
    [[ -z ${BUFFER} ]] && zle up-history
    [[ ${BUFFER} == sudo\ * ]] && BUFFER=${BUFFER#sudo } || BUFFER="sudo ${BUFFER}"
}

# ^[ == escape
bindkey '^[^[' _sudo_cmdline
```

#### _prompt_

my prompt looks like

```
13:38:33 ~/.config/zsh 0:00:06
main »
```

Which is:
```
time current-working-directory previous-command-execution-time
[screen]-[git-repo-branch] [ssh-user@host]»
```

With things in `[]` only showing if they have a valid value,
and `[ssh-user@host]»` changing color based on if the previous command exited with `0`

```
#!/usr/bin/env zsh

export PROMPT_EOL_MARK=''

function _preexec() {
    typeset -g prompt_timestamp=$EPOCHSECONDS
}

function _precmd() {
    integer elapsed=$(( EPOCHSECONDS - ${prompt_timestamp:-$EPOCHSECONDS} ))
    local human="$(( elapsed / 3600 )):${(l:2::0:)$(( elapsed / 60 % 60 ))}:${(l:2::0:)$(( elapsed % 60 ))}"
    vcs_info 2>&1 >/dev/null
    local newline=$'\n%{\r%}'

    PROMPT="%F{green}%*%f %F{blue}%~%f %F{yellow}${human}%f"
    PROMPT+="${newline}"
    PROMPT+="%F{242}${STY:+screen-}${VIRTUAL_ENV:+venv-}${vcs_info_msg_0_:+${vcs_info_msg_0_} }%f"
    PROMPT+="%(?.%F{magenta}.%F{red})${SSH_CONNECTION+%n@%m}»%f "
}

add-zsh-hook precmd  _precmd
add-zsh-hook preexec _preexec
```
