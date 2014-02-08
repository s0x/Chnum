#!/bin/bash
#
# This file contains a collection of functions
# used by all chnum-scripts
#

#
# Source a given file if it exists.
# Will search for a proper in PWD and
# CHNUM_INC.
# return: 0 if loaded successfully, 1 otherwise
include() {
  path=$1
  [[ -f $path ]] || {
    path=$CHNUM_INC/$path
  }
  [[ -f $path ]] || return 1
  source $path
}
