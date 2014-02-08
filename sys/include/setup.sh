#!/bin/bash
#
# This script provides all functions for setting up Chnum
#

include logging.sh || exit 1

#
# Check md5 and/or sha1 sum of file 
#
# @param file
# @param md5
# @param sha1
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

fn_exists() {
  type -t $1 | grep -q '^function$'
}

setup-env () {
  log_info "Seting-Up Fake Environment ..."
  for repo in $(ls $REPO_DIR/); do
    repo_path=$REPO_DIR/$repo
    [[ -d $repo_path ]] || continue
    log_info "Browse repo ${repo} ..."

    for package in $(ls $repo_path); do
      package_path=$repo_path/$package
      [[ -d $package_path ]] || continue
      log_info "Setup package ${package} ..."

      # Setup variables
      PACKAGE=$package
      DISTDIR=$PKG_DIR/$PACKAGE
      WORKDIR=$TMP_DIR/$PACKAGE/work
      DESTDIR=$TMP_DIR/$PACKAGE/image
      ARCHIVE=()

      #include $CFG_DIR/${package}.conf
      if ! include $package_path/${package}.setup; then
        log_error "${package} skipped. The file ${package}.setup was not found."
        break
      fi

      # create package directory
      mkdir -p $DISTDIR

      # fetch all needed files
      if ! (
        cd $DISTDIR

        for idx in "${!FILES[@]}"; do
          file=`basename ${FILES[$idx]}`

          while true; do

            # Download file
            while [ ! -f $file ]; do
              log_item "Downloading ${FILES[$idx]} ..."

              if fn_exists "fetch"; then
                # custom fetch function
                fetch
              else
                # default fetch
                if ! wget ${FILES[$idx]}; then
                  log_error "ERROR: Downloading ${file} failed."
                  if confirm "Retry?"; then
                    continue
                  fi
                else
                  log_ok "Downloading ${file} finished successfully."
                fi
              fi
              break;
            done

            # Checking File
            [ -f $file ] || return 1
            log_item "Checking checksums ..."
            if [[ -z $MD5[$idx] || -z $SHA1[$idx] ]]; then
              log_warn "WARNING: md5 and sha1 should be provided to prevent using corrupted or manipulated files"
            fi
            if ! check-files $file ${MD5[$idx]} ${SHA1[$idx]}; then
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

      # create working directory
      rm -rf $TMP_DIR/$PACKAGE
      mkdir -p $WORKDIR
      mkdir -p $DESTDIR

      # start setup process
      (
        cd $WORKDIR
        for url in $FILES; do
          file=`basename $url`;
          ARCHIVE+=($DISTDIR/$file)
        done
        # start unpacking

        env_begin "Unpacking fetched sources ..."
        unpack && env_end || exit 1

        env_begin "Setting up ${PACKAGE} ..."
        setup && env_end || exit 1

        env_begin "Install ${PACKAGE} ..."
        cd $DESTDIR
        cp -a . $ROOT_DIR && env_end || env_fail
      )
      env_begin "Removing temporary files ..."
      # cleanup
      cd $ROOT_DIR
      rm -rf $TMP_DIR/$PACKAGE
      env_end
    done
  done
}

