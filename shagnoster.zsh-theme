precmd() {
    print
}

() {
    SEGMENT_SEPARATOR=$'\ue0b0'
    FIRST=true
}

shrink_path () {
  setopt localoptions
  setopt rc_quotes null_glob

  typeset -a tree expn
  typeset result part dir=${PWD}
  typeset -i i

  [[ -d $dir ]] || return 0

  if [[ $dir == $HOME ]] {
    icon=''
  } else {
    icon=''
  }

  dir=${dir/$HOME/\~}
  tree=(${(s:/:)dir})
  (
    unfunction chpwd 2> /dev/null
    if [[ $tree[1] == \~* ]] {
      cd ${~tree[1]}
      result=$tree[1]
      shift tree
    } else {
      cd /
    }
    for dir in $tree; {
      if (( $#tree == 1 )) {
        result+="/$tree"
        break
      }
      expn=(a b)
      part=''
      i=0
      until [[ (( ${#expn} == 1 )) || $dir = $expn || $i -gt 99 ]]  do
        (( i++ ))
        part+=$dir[$i]
        expn=($(echo ${part}*(-/)))
        # (( short )) && break
      done
      result+="/$part"
      cd $dir
      shift tree
    }
    echo $icon ${result:-/}
  )
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $FIRST != true && $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
    FIRST=false
  fi
}

# Dir: current working directory
prompt_dir() {
  # prompt_segment blue black '%~'
  prompt_segment blue black '$(shrink_path -l -t)'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path ]]; then
    prompt_segment yellow black " $(basename $virtualenv_path)"
    FIRST=false
  fi
}

prompt_newline() {
    print
}


## Main prompt
build_prompt() {
  prompt_virtualenv
  # prompt_context
  prompt_dir
  prompt_end
}

setopt PROMPT_SUBST
PROMPT="%{%f%b%k%}$(build_prompt) "
