precmd() {
    print
}

() {
    # SEGMENT_SEPARATOR=$'\ue0b0'
    SEGMENT_SEPARATOR=' '
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
      if (( $#tree == 1 )) { result+="/$tree"; break; }
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

gitprompt() {
    git status --branch --porcelain=v2 2>&1 | awk '
        BEGIN {
            fatal = 0;
            oid = "";
            head = "";
            ahead = 0;
            behind = 0;
            untracked = 0;
            unmerged = 0;
            staged = 0;
            unstaged = 0;
        }

        $1 == "fatal:" { fatal = 1; }
        $2 == "branch.oid" { oid = $3; }
        $2 == "branch.head" { head = $3; }
        $2 == "branch.ab" { ahead = $3; behind = $4; }
        $1 == "?" { ++untracked; }
        $1 == "u" { ++unmerged; }

        $1 == "1" || $1 == "2" {
            split($2, arr, "");
            if (arr[1] != ".") { ++staged; }
            if (arr[2] != ".") { ++unstaged; }
        }

        END {
            if (fatal == 1) { exit(1); }

            printf "%s ", ""

            if (head == "(detached)") {
                printf ":%s ", substr(oid, 0, 7);
            } else {
                printf "%s ", head;
            }

            if (behind < 0) { printf "↓%d", behind * -1; }
            if (ahead > 0) { printf "↑%d", ahead; }
            if (unmerged > 0) { printf "✖%d", unmerged; }
            if (staged > 0) { printf "●%d", staged; }
            if (unstaged > 0) { printf "%d", unstaged; }
            if (untracked > 0) { printf "…%d", untracked; }
            if (unmerged == 0 && staged == 0 && unstaged == 0 && untracked == 0) { printf "✔" }
        }
    '
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
  if $HOST_IN_PROMPT && [[ -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$HOST"
    FIRST=false
  fi
}

# Dir: current working directory
prompt_dir() {
  # prompt_segment blue default '%~'
  prompt_segment black blue '$(shrink_path -l -t)'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path ]]; then
    prompt_segment black yellow " $(basename $virtualenv_path)"
    FIRST=false
  fi
}

prompt_git() {
    # local gp=$(gitprompt)
    # [[ ! -z "$gp" ]] && {
        # prompt_segment red black " ${gp}"
        # FIRST=false
    # }
    prompt_segment black red '$(gitprompt)' 
    FIRST=false
}

prompt_newline() {
    print
}


## Main prompt
build_prompt() {
  prompt_context
  prompt_virtualenv
  prompt_git
  prompt_dir
  prompt_end
}

build_rprompt() {
}

MODE_INDICATOR="NORMAL"

setopt PROMPT_SUBST
PROMPT="%{%f%b%k%}$(build_prompt)"
RPROMPT="$(build_rprompt)"
