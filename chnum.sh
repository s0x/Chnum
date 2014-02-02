#!/bin/sh
#
# Bash script to initialize the local fake environment

ROOT_DIR=$HOME/chnum

SYS_DIR=$ROOT_DIR/sys
INC_DIR=$SYS_DIR/include
SETUP_DIR=$SYS_DIR/setup.d
ENV_DIR=$SYS_DIR/env.d
CFG_DIR=$SYS_DIR/conf.d
TMP_DIR=$SYS_DIR/tmp
PKG_DIR=$SYS_DIR/cache/files
LOG_DIR=$SYS_DIR/log

today=(date +"%Y%m%d%H%M")
LOG_FILE=$LOG_DIR/env_$today.log

export PATH=$PATH:$ROOT_DIR/bin:$ROOT_DIR/usr/bin

REAL_HOME=$HOME
# search for local home directories
for i in $(ls $ROOT_DIR/home); do
  # temporary change home directory
  HOME=$ROOT_DIR/home/$i

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

# setup fake environment entries
for i in $(ls $ENV_DIR/*.env); do
  source $i
done;

include() {
  [ -f $1 ] || return 1
  source $1
}

include $INC_DIR/logging.sh
include $INC_DIR/setup.sh

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

