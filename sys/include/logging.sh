#!/bin/sh
#
# This script provides some functions for fancy logging
#

NORMAL=$(tput sgr0)

BOLD=$(tput bold)

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)

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
  [[ -z $1 ]] || log_msg "${1}"
  printf "\n"
}

log_ok() {
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#GREEN}+${#NORMAL}+$MSG_OFFSET

  printf "%${COL}s" "$GREEN[OK]$NORMAL"
  unset MSG
}

log_warn() {
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#YELLOW}+${#NORMAL}+$MSG_OFFSET

  printf "%${COL}s" "$YELLOW[WARN]$NORMAL"
  unset MSG
}

log_error() {
  [[ -z $1 ]] || log_msg "${1}"
  let COL=$(tput cols)-${#MSG}+${#BOLD}+${#RED}+${#NORMAL}+$MSG_OFFSET

  printf "%${COL}s" "$BOLD$RED[!!]$NORMAL"
  unset MSG
}

env_begin() {
  log_msg $1
}

env_fail() {
  log_error
}

env_end() {
  log_ok
}
