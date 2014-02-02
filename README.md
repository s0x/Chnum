Chnum
=====

Lightweight set of scripts to create a local fake environment

Please note that Chnum is under heavy development. Therefore a lot of things might change in future

Installation
=====

Clone the repo into your home directory and add the following line to your .bashrc


```shell
. ${HOME}/Chnum/chnum.sh
```

Setup
=====

Setup your local environment with all packages placed in the setup.d directory by calling

```shell
setup-env
```
Packages
=====

All packages will be placed in the setup.d directory for now. Most probably a
separate repo directory will be created in future to allow multiple sources for
package files.

A package basically consists of a setup script which will be called to build
and install the package. Futhermore there might be additional ressources like
patches and configuration files

    examplepkg/         -- package directory
      examplepkg.setup  -- setup script
      files/            -- additional files
        examplepkg.conf -- configuration file
        examplepkg.env  -- env-file to be sourced
    
As you would guess the package structure and setup routines are looking quite
similar to the once used in gentoo's portage. Actually it is based on it.
