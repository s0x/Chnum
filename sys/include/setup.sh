#!/bin/bash
#
# This script provides all functions for setting up Chnum
#


#
# Check md5 and/or sha1 sum of file 
#
# @param file
# @param md5
# @param sha1
#
check-files() {
  [[ -n $2 ]] || log_warn "WARNING: md5sum was not provided. Skipped check!"
  if [[ -n $2 ]]; then
    log_item "Checking md5 ..."
    md5=($(md5sum ${1}))
    if [[ $md5 != $2 ]]; then
      log_error " ERROR: md5 doesnt match. The file might be corrupt"
      return 1
    fi
    log_ok
  fi

  [[ -n $3 ]] || log_warn "WARNING: sha1sum was not provided. Skipped check!"
  if [[ -n $3 ]]; then
    log_item "Checking sha1 ..."
    sha1=($(sha1sum ${1}))
    if [[ $sha1 != $3 ]]; then
      log_error " ERROR: sha1 doesnt match. The file might be corrupt"
      return 1
    fi
    log_ok
  fi
  return 0;
}

setup-env () {
  log_info "Seting-Up Fake Environment ..."
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

