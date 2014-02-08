#!/bin/sh
#
# Bash script to initialize the local fake environment

export CHNUM_HOME=$HOME/chnum

export PATH=$PATH:$CHNUM_HOME/sys/bin:$CHNUM_HOME/usr/bin

REAL_HOME=$HOME
# search for local home directories
for i in $(ls $CHNUM_HOME/home); do
  # temporary change home directory
  HOME=$CHNUM_HOME/home/$i

  # Add bin directory
  if [[ -d $HOME/bin ]]; then
    export PATH=$PATH:$HOME/bin
  fi
  # Source env file
  if [[ -f $HOME/env.sh ]]; then
    source $HOME/env.sh
  fi
done
HOME=$REAL_HOME
unset REAL_HOME

# load all environment files
for i in $(ls $CHNUM_HOME/etc/env.d/); do
  [[ ${i##*.} == "env" ]] || continue
  source $CHNUM_HOME/etc/env.d/$i
done;

confirm() {
  while true; do
    read -p "$1 [yN]: " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      "" ) return 1;;
    esac
  done
}
