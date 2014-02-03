#!/bin/sh
#
# Bash script to initialize the local fake environment

CHNUM_HOME=$HOME/chnum

SYS_DIR=$CHNUM_HOME/sys
INC_DIR=$SYS_DIR/include
ENV_DIR=$CHNUM_HOME/etc/env.d
CFG_DIR=$CHNUM_HOME/etc/conf.d
REPO_DIR=$CHNUM_HOME/usr/chnum/repos
TMP_DIR=$CHNUM_HOME/tmp
PKG_DIR=$CHNUM_HOME/var/cache/chnum
LOG_DIR=$CHNUM_HOME/var/log/chnum

mkdir -p $ENV_DIR
mkdir -p $CFG_DIR
mkdir -p $REPO_DIR

today=$(date +"%Y%m%d%H%M")

LOG_FILE=$LOG_DIR/chnum.${today}.log

export PATH=$PATH:$CHNUM_HOME/bin:$CHNUM_HOME/usr/bin

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

# setup fake environment entries
for i in $(ls $ENV_DIR); do
  [[ ${i##*.} == "env" ]] || continue
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

