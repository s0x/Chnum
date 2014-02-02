#!/bin/sh
#
# Bash script to initialize the local fake environment

ROOT_DIR=$HOME/chnum

SYS_DIR=$ROOT_DIR/sys
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

log_msg() {
  MSG=$1
  printf "%s" "$MSG"
}

log_ok() {
  GREEN=$(tput setaf 2)
  NORMAL=$(tput sgr0)
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#GREEN}+${#NORMAL}

  printf "%${COL}s\n" "$GREEN[OK]$NORMAL"
}

log_warn() {
  YELLOW=$(tput setaf 3)
  NORMAL=$(tput sgr0)
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#YELLOW}+${#NORMAL}

  printf "%${COL}s\n" "$YELLOW[WARN]$NORMAL"

}

log_error() {
  BOLD=$(tput bold)
  RED=$(tput setaf 1)
  NORMAL=$(tput sgr0)
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#BOLD}+${#RED}+${#NORMAL}

  printf "%${COL}s\n" "$BOLD$RED[!!]$NORMAL"
}

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

env_begin() {
  log_msg $1
}

#
# Check md5 and/or sha1 sum of file 
# @param file
# @param md5
# @param sha1
#
check-files() {
  [[ -n $2 ]] || log_warn "WARNING: md5sum was not provided. Skipped check!"
  if [[ -n $2 ]]; then
    log_msg "Checking md5 ..."
    md5=($(md5sum ${1}))
    if [[ $md5 != $2 ]]; then
      log_error
      log_error " ERROR: md5 doesnt match. The file might be corrupt"
      return 1
    fi
    log_ok
  fi

  [[ -n $3 ]] || echo "WARNING: sha1sum was not provided. Skipped check!"
  if [[ -n $3 ]]; then
    log_msg "Checking sha1 ..."
    sha1=($(sha1sum ${1}))
    if [[ $sha1 != $3 ]]; then
      log_error
      log_error " ERROR: sha1 doesnt match. The file might be corrupt"
      return 1
    fi
    log_ok
  fi
  return 0;
}

setup-env () {
  echo "Seting-Up Fake Environment"
  for service in $(ls $SYS_DIR/setup.d/); do

    # create package directory
    mkdir -p $PKG_DIR/$service

    # fetch all needed files
    if ! (
      cd $PKG_DIR/$service
      source $SYS_DIR/conf.d/${service}.conf
      source $SYS_DIR/setup.d/${service}/${service}.setup

      for idx in "${!files[@]}"; do
        file=`basename ${files[$idx]}`

        while true; do
          
          # Download file
          while [ ! -f $file ]; do
            echo "Downloading ${files[$idx]} ..."
            if ! wget ${files[$idx]}; then
              log_error "ERROR: Downloading ${file} failed."
              if confirm "Retry?"; then
                continue
              fi
            else
              log_ok "Downloading ${file} finished successfully."
            fi
            break;
          done

          # Checking File
          [ -f $file ] || return 1
          echo "Checking checksums ..."
          if [[ -z $md5[$idx] || -z $sha1[$idx] ]]; then
            log_warn "WARNING: md5 and sha1 should be provided to prevent using corrupted or manipulated files"
          fi
          if ! check-files $file ${md5[$idx]} ${sha1[$idx]}; then
            if confirm "Retry downloading the file ${file}?"; then
              rm $file
              continue
            else
              return 1
            fi
          fi
          break
        done
          
      done
    ); then
      log_error "ERROR: Not able to collect all needed files"
      continue
    fi

    working_dir=$TMP_DIR/${today}-${service}

    # create working directory
    mkdir -p $working_dir

    # start setup process
    (
      cd $working_dir
      source $SYS_DIR/conf.d/${service}.conf
      source $SYS_DIR/setup.d/${service}/${service}.setup
      for url in $files; do
        file=`basename $url`;
        cp $PKG_DIR/$service/$file .
      done
      setup
    )
    # cleanup
    cd $ROOT_DIR
    rm -rf $working_dir
  done
#  for i in $(ls $SYS_DIR/init.d/); do
#    $SYS_DIR/init.d/$i setup
#  done
}

