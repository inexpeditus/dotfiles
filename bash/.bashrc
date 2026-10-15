# ~/.bashrc

# Only run for interactive shells
[[ $- != *i* ]] && return

export HISTSIZE=100000
export HISTFILESIZE=200000
shopt -s histappend
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
PROMPT_COMMAND='history -a; history -n'

# Shell 

shopt -s checkwinsize cdspell autocd globstar nocaseglob
stty -ixon 2>/dev/null   # free up Ctrl-S
export LESS='-FRX'

for _p in "$HOME/.pi/agent/bin" "$HOME/.local/bin"; do
    case ":$PATH:" in *":$_p:"*) ;; *) PATH="$_p:$PATH" ;; esac
done
unset _p
export PATH

# .NET SDK (user-level install) and CSharpier, used by nvim format-on-save
export DOTNET_ROOT="$HOME/.dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
case ":$PATH:" in *":$DOTNET_ROOT/tools:"*) ;; *) PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH" ;; esac
export LIBVIRT_DEFAULT_URI=qemu:///system

# Functions

mkalias() {
    if grep -q "^alias $1=" ~/.bashrc; then
        echo "alias '$1' already exists in ~/.bashrc" >&2
        return 1
    fi
    printf 'alias %s=%q\n' "$1" "$2" >> ~/.bashrc && alias "$1=$2"
}

copy() {
    if [ "$#" -eq 1 ]; then
        xclip -sel clip < "$1"
    else
        xclip -sel clip
    fi
}

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

extract() {
    [ -f "$1" ] || { echo "extract: '$1' is not a file" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar.zst)        tar --zstd -xf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.7z)             7z x "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.xz)             unxz "$1" ;;
        *)                echo "extract: unknown format '$1'" >&2; return 1 ;;
    esac
}

# Prompt

PROMPT_DIRTRIM=1
PS1='[\u: \w]\$ '

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
    command -v fd >/dev/null 2>&1 && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
fi

# Alias

# because of that one time nvim felt bloat so you're forced to vi to remove alias vim=nvim to run vim
for _ed in nvim vim vi; do
    if command -v "$_ed" >/dev/null 2>&1; then
        alias v="$_ed" vim="$_ed" nvim="$_ed"
        export EDITOR="$_ed" VISUAL="$_ed"
        break
    fi
done
unset _ed

alias sudo='sudo '       # lets aliases work after sudo
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias bness='xrandr --output eDP1 --brightness'
alias rlb='source ~/.bashrc'
alias dirsizes='du -sh'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alFh'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

# Stupid lazy
alias reflector='sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'
alias lsfiles='ls -p | grep -v /$'
alias lsdirs='ls -d */ 2>/dev/null'
alias zap='~/roy/scripts/zip_and_send.sh' # keep unless syncthing once static ip for the openBSD system is resolved
alias t='~/roy/scripts/time2.sh' # stupid script to avoid basic math in milen - rename
alias du_simple='du -h --max-depth=1 ./ | sort -hr'
alias mmm='mpv --hwdec=auto .'
alias mpv='prime-run mpv'

# OAuth
alias aws-totp='oathtool --totp -b "$(cat ~/roy/.totp_keys/.aws_inexpeditus)" | copy'
alias git-totp='oathtool --totp -b "$(cat ~/roy/.totp_keys/.github_inexpeditus)" | copy'

# fix aws
# alias passcode_git="keepassxc-cli clip -t ~/.roy/roys_db.kdbx 'INEXPEDITUS - Github'"
