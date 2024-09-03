HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

setopt AUTO_CD
setopt CORRECT
setopt EXTENDED_GLOB
setopt NO_BEEP
setopt NO_CASE_GLOB
setopt NO_CLOBBER
setopt NUMERIC_GLOB_SORT
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME
setopt RM_STAR_WAIT
setopt TRANSIENT_RPROMPT

bindkey -v
autoload -U compinit && compinit
autoload -U colors && colors

# Use an interactive menu for completions.
zstyle ':completion:*:*:*:default' menu yes select search

export EDITOR="vim"
export COMPLETION_WAITING_DOTS="true"

# Automatic sudo (M-e)
insert_sudo() { zle beginning-of-line; zle -U "sudo " }
zle -N insert-sudo insert_sudo
bindkey "^[e" insert-sudo

#source ~/.zshplug/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zshplug/fzf-tab-completion/zsh/fzf-zsh-completion.sh
source ~/.zshplug/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source ~/.zshplug/zsh-fzf-history-search/zsh-fzf-history-search.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Use ^I to activate fzf for a single file, and ^P for multiple.
insert-fzf-output() {
  local output
  output=$(fzf -m < /dev/tty | awk '{ print "\""$0"\"" }' | tr '\n' ' ') && LBUFFER+=${output}
}
zle -N insert-fzf-output

bindkey '^I' fzf_completion
bindkey '^P' insert-fzf-output

# Set up the OCaml environment.
eval `opam env`

alias ls='ls --color=auto'
alias la='ls -la'
alias recd='cd "$(pwd)"'
alias newemacs='open -n -a emacs'

clear
echo "\033[1m`whoami`\033[00m on \033[1m`hostname`\033[0m"
date
echo "`uname -s` `uname -r`"

function preexec() {
  timer=${timer:-$SECONDS}
}

function precmd() {
  # Stash the exit code of the last command before we execute anything as part
  # of the prompt.
  local last_rc=$?

  # Determine whether we are in a git repository: if we are, output the
  # current branch and modification status.
  git rev-parse 2> /dev/null
  if [ $? -ne 128 ]; then
    local git_branch="`git rev-parse --abbrev-ref HEAD`"
    local git_suffix_logical=" on ${git_branch}"

    if [[ `git status --porcelain` ]]; then
      local git_suffix=" on %F{red}${git_branch}%f"
    else
      local git_suffix=" on %F{green}${git_branch}%f"
    fi
  fi

  # Truncate all directories in the CWD save for the last to their first
  # character, allowing for entire paths to be displayed on a single line of an
  # 80-column terminal.
  local curdir="`pwd | sed "s|^$HOME|~|" 2> /dev/null | sed 's/\([^/]\)[^/]*\//\1\//g'`"

  # If the last command exited successfully, print the prompt in green;
  # otherwise, print it in red and include the exit code in the pre-prompt line.
  if [ $last_rc -eq 0 ]; then
    local prompt_colour="%F{green}"
  else
    local prompt_colour="%F{red}"
    local rc_suffix_logical="${last_rc} ─ "
    local rc_suffix="%F{red}${last_rc}%f ─ "
  fi

  # The pre-prompt line ends with the current time and duration of the previous
  # command. In said line, we output this information in a colourised format;
  # however, we also need to compute the display length to construct the
  # horizontal rule that comprises the center of the line.
  if [ $timer ]; then
    local timer_show=$(($SECONDS - $timer))
  else
    local timer_show=0
  fi
  local time_suffix_logical="${rc_suffix_logical}${HISTCMD} at `date +"%H:%M:%S"` (${timer_show}s)"

  # We have now constructed all portions of the pre-prompt line: determine the
  # length of the horizontal rule in the center.
  local rule_width=$((COLUMNS-${#curdir}-${#git_suffix_logical}-${#time_suffix_logical}-3))

  # Use a different character for the prompt to differentiate between standard
  # users and root.
  if [[ $EUID > 0 ]]; then
    local prompt_char='$'
  else
    local prompt_char='#'
  fi

  # The standard prompt is simply comprised of the prompt character. The entire
  # multi-line inter-command output is not included in the prompt in order to
  # circumvent persistent multi-line prompt display issues in some terminals.
  export PROMPT="%B${prompt_colour}${prompt_char}%f%b "

  # Output the pre-prompt line.
  print ""
  print -rP "%B%F{cyan}${curdir}%f%b${git_suffix} ${(l(${rule_width})(─))} ${rc_suffix}${HISTCMD} at %F{yellow}`date +"%H:%M:%S"`%f (${timer_show}s)"

  # If there are any background jobs running, display them in a right prompt;
  # otherwise, leave the right prompt empty.
  local bg_jobs=`jobs | wc -l | sed 's/[[:space:]]//g'`
  if [[ $bg_jobs > 0 ]]; then
    local jobs_suffix=" %F{red}[${bg_jobs}]%f"
  fi

  export RPROMPT="%F{white}%n@%m%f${jobs_suffix}"

  unset timer
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/awsmith/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/awsmith/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/awsmith/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/awsmith/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# rbenv configuration
export PATH="/Users/awsmith/.rbenv:$PATH"
eval "$(rbenv init - zsh)"

# qmk configuration
#export PATH="/opt/homebrew/opt/avr-gcc@8/bin:/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"

# Latest LLVM and libc.
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib/c++ -L/opt/homebrew/opt/llvm/lib -lunwind"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
