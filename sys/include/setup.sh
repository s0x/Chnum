#!/bin/bash
#
# This script provides all functions for setting up Chnum
#

setup-env () {
  echo "Seting-Up Fake Environment"
  for service in $(ls $SETUP_DIR); do
    include $CFG_DIR/${service}.conf
    if ! include $SETUP_DIR/${service}/${service}.setup; then
      log_error "${service} skipped. The file ${service}.setup was not found."
      break
    fi

    # create package directory
    mkdir -p $PKG_DIR/$service

    # fetch all needed files
    if ! (
      cd $PKG_DIR/$service

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
          log_item "Checking checksums ..."
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
}

