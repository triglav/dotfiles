#!/bin/sh
#
# install.sh - installs dotfiles from git repository to the $HOME directory
# Maintainer: Triglav <trojhlav@gmail.com>
#
# Credit goes to 'https://github.com/jferris/config_files'
# I have modified/fixed it a little for Ubuntu's (da)sh.

cutstring="DO NOT EDIT BELOW THIS LINE"

for name in *; do
  target="$HOME/sandbox/.$name"
  # if the target exists
  if [ -e "$target" ]; then
    # and if it is not a sym link
    if [ ! -h "$target" ]; then
      # we assume there is a modification in the file and contains the
      # $cutstring, which separates the local changes and general content from
      # git repository

      # find $cutstring in the existing file and get the line number
      cutline=`grep -n -m1 "$cutstring" "$target" | sed "s/:.*//"`
      # if the $cutstring line has been found
      if [ -n "$cutline" ]; then
        # decrement $cutline
        cutline=`expr $cutline - 1`
        #let "cutline = $cutline - 1"
        echo "Updating $target"
        # read the lines till the $cutline and push them to a temp file
        head -n "$cutline" "$target" > update_tmp
        # search for $cutstring backwards in the local file
        startline=`tac "$name" | grep -n -m1 "$cutstring" | sed "s/:.*//"`
        #startline=`tail -r "$name" | grep -n -m1 "$cutstring" | sed "s/:.*//"`
        # if the $cutstring line has been found
        if [ -n "$startline" ]; then
          # attach the content below the line to the temp file
          tail -n "$startline" "$name" >> update_tmp
        else
          # attach the whole content to the temp file
          cat "$name" >> update_tmp
        fi
        # overwrite the dotfile in the home directory with generated temp file
        mv update_tmp "$target"
      else
        echo "WARNING: $target exists but is not a symlink."
      fi
    fi
  else
    # skip the current script file
    if [ "$name" != "install.sh" ]; then
      echo "Creating $target"
      # if the file contains $cutstring, create a copy of it
      if [ -n "`grep "$cutstring" "$name"`" ]; then
        cp "$PWD/$name" "$target"
      # otherwise create a symbolic link
      else
        ln -s "$PWD/$name" "$target"
      fi
    fi
  fi
done
