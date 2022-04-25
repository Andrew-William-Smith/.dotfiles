HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt AUTO_CD
setopt CORRECT
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME

setopt NO_BEEP
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT
setopt EXTENDED_GLOB

setopt NO_CLOBBER
setopt RM_STAR_WAIT

bindkey -v
autoload -U compinit && compinit

# Use an interactive menu for completions.
zstyle ':completion:*:*:*:default' menu yes select search

autoload -U colors && colors
function genprompt() {
  local i currdir currtime arrowcol gitbranch gitappendcalc gitappend gitcol exitappend localstat

  # Determine if in a git repository
  git rev-parse 2> /dev/null
  if [ $? -ne 128 ]; then
    if [[ `git status --porcelain` ]]
      then gitcol="%{$fg[red]%}"
      else gitcol="%{$fg[green]%}"
    fi
    gitbranch=`git rev-parse --abbrev-ref HEAD`
    gitappendcalc=" on ${gitbranch}"
    gitappend=" on ${gitcol}${gitbranch}%{$reset_color%}"
  fi

  currdir="`pwd | sed "s|^$HOME|~|" 2> /dev/null | sed 's/\([^/]\)[^/]*\//\1\//g'`"

  if [ $rc -eq 0 ]
    then arrowcol="%{$fg[green]%}"
    else arrowcol="%{$fg[red]%}"; exitappend=" ${rc} ─"
  fi

  currtime="${exitappend}${HISTCMD} at `date "+%H:%M:%S"` (${timer_show}s)"
  newprompt="%B%{${fg[cyan]}%}${currdir}%b%{${reset_color}%}${gitappend} "

  for ((i=${#currdir}-1+${#gitappendcalc}; i<=COLUMNS-4-${#currtime}; i+=1)) do
    newprompt="${newprompt}─"
  done

  if [ $rc -eq 0 ]
  then exitappend=""
  else exitappend=" %{${fg[red]}%}${rc}%{${reset_color}%} ─"
  fi

  export PROMPT="${newprompt}${exitappend} ${HISTCMD} at %{${fg[yellow]}%}`date "+%H:%M:%S"`%{${reset_color}%} (${timer_show}s)${arrowcol}▶%{${reset_color}%} "
}
genprompt

EDITOR="vim"
COMPLETION_WAITING_DOTS="true"

# Automatic sudo (M-e)
insert_sudo() { zle beginning-of-line; zle -U "sudo " }
zle -N insert-sudo insert_sudo
bindkey "^[e" insert-sudo

source ~/.zshplug/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zshplug/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

alias ls='ls --color=auto'
alias la='ls -la'

clear
# fortune -a | cowsay -f $(ls /usr/local/share/cows | gshuf -n1) | lolcat
echo "\033[1m`whoami`\033[00m on \033[1m`hostname`\033[0m"
date
echo "`uname -o` `uname -r`"
echo

function preexec() {
    timer=${timer:-$SECONDS}
}

function precmd() {
    rc=$?
    if [ $timer ]; then
        timer_show=$(($SECONDS - $timer))
        echo
        genprompt
        unset timer
    fi
}
