#!/bin/sh
#
# install.sh - installs dotfiles from git repository to the $HOME directory
# Maintainer: Triglav <trojhlav@gmail.com>
#
# Credit for the main idea of this file goes to
# 'https://github.com/jferris/config_files'
# I have modified/fixed it a little for my needs.

cutstring="DO NOT EDIT BELOW THIS LINE"
basedir="`dirname $0`"
target_dir="$HOME"

usage()
{
  echo "Usage: ./install.sh [OPTION]..."
  echo "Install dotfiles to the \$HOME directory"
  echo
  echo "  -s, --sand-box PATH     dotfiles will be installed to this directory"
  echo "                          instead of \$HOME. Great option for testing."
  echo "  -h, --help              display this help and exit"
  echo
  echo "Report bugs to <trojhlav@gmail.com>"
}

while [ "$1" != "" ]; do
  case $1 in
    -s | --sand-box )
      shift
      if [ ! -n "$1" ]; then
        usage
        exit
      elif [ -d "$1" ]; then
        target_dir="`readlink -f $1`"
      else
        echo "$1: invalid directory"
        exit
      fi
      ;;
    -h | --help )
      usage
      exit
      ;;
    * )
      usage
      exit 1
  esac
  shift
done

for file in $basedir/*; do
  name="`basename $file`"
  target="$target_dir/.$name"
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
        # read the lines till the $cutline and push them to a temp file
        head -n "$cutline" "$target" > update_tmp
        # search for $cutstring backwards in the local file
        startline=`tac "$file" | grep -n -m1 "$cutstring" | sed "s/:.*//"`
        # if the $cutstring line has been found
        if [ -n "$startline" ]; then
          # attach the content below the line to the temp file
          tail -n "$startline" "$file" >> update_tmp
        else
          # attach the whole content to the temp file
          cat "$file" >> update_tmp
        fi
        # if there are any changes
        if [ -n "`comm -13 --nocheck-order update_tmp "$target"`" ]; then
          # overwrite the dotfile in the home directory with generated temp file
          while true; do
            echo "WARNING: There is a conflict with '$target'."
            read -p "Do you wish to overwrite it? [yna] " yna
            case $yna in
              [Yy] )
                echo "Overwriting '$target'."
                mv update_tmp "$target"
                break;;
              [Nn] )
                echo "Skipping '$target'."
                rm -f update_tmp
                break;;
              [Aa] )
                echo "Aborting."
                rm -f update_tmp
                return;;
            esac
          done
        else
          rm -f update_tmp
        fi
      else
        while true; do
          echo "WARNING: '$target' exists but is not a symlink."
          read -p "Do you wish to overwrite it? [yna] " yna
          case $yna in
            [Yy] )
              echo "Overwriting '$target'."
              rm -f "$target"
              ln -s "`readlink -f $file`" "$target"
              break;;
            [Nn] )
              echo "Skipping '$target'."
              break;;
            [Aa] )
              echo "Aborting."
              return;;
          esac
        done
      fi
    fi
  else
    # skip the current script file
    if [ "$name" != "install.sh" ]; then
      echo "Creating '$target'."
      # if the file contains $cutstring, create a copy of it
      if [ -n "`grep "$cutstring" "$file"`" ]; then
        cp "$file" "$target"
      # otherwise create a symbolic link
      else
        ln -s "`readlink -f $file`" "$target"
      fi
    fi
  fi
done
