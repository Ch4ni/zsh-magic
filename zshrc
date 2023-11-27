echo "Profile loading from ${ZDOTDIR:=${HOME}}"

#export ZCONFDIR="$(realpath ${ZDOTDIR}/..)"
#if [[ "${ZCONFDIR}" == "$(realpath ${HOME}/../)" ]]; then
#  # if ZDOTDIR is ${HOME}, then reset ZCONFDIR to $HOME as well
#  export ZCONFDIR="${HOME}"
#fi

lazyFuncPath=${ZDOTDIR}/lazyfuncs
setopt extendedglob autocd

typeset -U fpath

fpath=(
  ${lazyFuncPath}/**/(F)
  $fpath
)

lazyFuncs=( ${lazyFuncPath}/**/*~*.zwc(.) )
autoload -UwR ${lazyFuncs}

bindkey -v

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
# TODO: learn more about zstyle/compinstall and generate completions for
# all my autoload funcs
zstyle :compinstall filename '${ZDOTDIR:=${HOME}}/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

## TEMPORARY - I don't yet well understand why these don't carry over from .zshenv
## give them a home here until I do

export source_sources=(
  "command:brew shellenv"
  "command:starship init zsh"
  "command:atuin init zsh --disable-up-arrow"
  "command:pyenv init -"
  "command:pyenv virtualenv init -"
  'deferred-file:${SDKMAN_DIR}/bin/sdkman-init.sh'
  'deferred-file:${HOMEBREW_PREFIX}/opt/asdf/libexec/asdf.sh'
)

declare -A __z_aliases
__z_aliases=(
  [zr]="zellij run"
  [zrd]="zellij run -d down"
  [zrr]="zellij run -d right"
  [zri]="zellij run -i"
  [zellaunch]="zellij options --theme tokyo-night-storm --default-shell=zsh"
  [exa]="eza"
)
## END TEMPORARY


# paths to add to $PATH/$path that live in $HOME, these will get
# prepended with ${HOME} when constructing the final path list
# It's also nice to use globbing to generate paths
# TODO: build this glob from $override_path_dir_names and 
# $exclude_override_path_dir_names
#   this can generate a PATHS file to avoid computing the glob every time
#   the shell starts - additionally, we can create a preexec hook that will
#   offer to recalculate/reload the $path if the command isn't found

override_path_glob="{,.}**/(${(pj.\|.)override_path_dir_names})~*(${(pj.\|.)exclude_override_path_dir_names})*"

override_paths=( $(print -l ${override_path_glob}) )

typeset -U homepaths
homepaths=(
  '{,.}**/(sbin|bin|alternatives|shims)~*(Code|Documents)*'
  )

for s in $source_sources; do
  # command:*       -> run the command and source the output like a file
  # file:*          -> source the file
  # deferred-file:* -> skip this for now, they will get evaluated later
  case $s in
    command:*) source <(eval ${s#command:});;
    file:*) eval source ${s#file:} 2>|sed '/^(eval)/d';;
  esac
done

# paths that come earlier in $PATH override entries that come after
overridepaths=(
  $(eval realpath ${homepaths/#/${HOME}/} 2>&1 | sed '/^(eval)/d')  # prefix homepaths with $HOME, expand globs
  /home/linuxbrew/.linuxbrew/{,Homebrew}/{bin,sbin}
)

# for things that don't need to override
appendpaths=()

# keep the path clean
typeset -U path
path=($overridepaths $path $appendpaths)

for s in ${(M)source_sources:#deferred-file:*}; do
  # deferred-file:* -> evaluate the file path, and then source the resulting file
  eval source ${s#deferred-file:*}
done

# populate the aliases
__process_aliases
