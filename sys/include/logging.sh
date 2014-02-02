#!/bin/sh
#
# This script provides some functions for fancy logging
#

NORMAL=$(tput sgr0)

BOLD=$(tput bold)

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)

split_msg() {
  IFS=$'\n' read -rd '' -a array <<< "$1"
  if [[ ${#array[@]} > 1 ]]; then
    for line in "${array[@]}"; do
      $2 "$line"
    done
    return 0
  else
    return 1
  fi
}

log_item() {
  log_msg " $YELLOW*$NORMAL $1"
  let MSG_OFFSET=${#YELLOW}+${#NORMAL}
}

log_msg() {
  [[ ! $MSG ]] || printf "\n"
  let MSG_OFFSET=0
  MSG=$1
  printf "%s" "$MSG"
}

log_info() {
  ! split_msg "$1" "log_info" || return
  [[ ! $1 ]] || log_item "${1}"
  printf "\n"
  unset MSG
}

log_ok() {
  ! split_msg "$1" "log_ok" || return
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#GREEN}+${#NORMAL}+$MSG_OFFSET

  printf "%${COL}s\n" "$GREEN[OK]$NORMAL"
  unset MSG
}

log_warn() {
  ! split_msg "$1" "log_warn" || return
  [[ ! $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#YELLOW}+${#NORMAL}+$MSG_OFFSET

  printf "%${COL}s\n" "$YELLOW[WARN]$NORMAL"
  unset MSG
}

log_error() {
  ! split_msg "$1" "log_error" || return
  [[ ! $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#BOLD}+${#RED}+${#NORMAL}+$MSG_OFFSET

  printf "%${COL}s\n" "$BOLD$RED[!!]$NORMAL"
  unset MSG
}

env_begin() {
  log_item "${1}"
}

env_try() {
  local cmd="${1}"
  local log=$($cmd 2>&1)
  #echo $log
  if [[ $log ]]; then
    log_error "${log}"
    return 1
  fi
}

env_fail() {
  log_error "${1}"
}

env_end() {
  log_ok
}
