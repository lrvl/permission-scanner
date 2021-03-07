#! /usr/bin/env bash
#
# Purpose: Scan directories which open the permission bits to wider audiences
# Author:  Leroy van Logchem
# Created: March 2021
# OS:      FreeBSD (for Linux change the stat to -f"%p")
#

#
# Function: Recurse into the directory tree
#
recurse_tree() {
  ls "$1" | while IFS= read -r i; do
    if [ -d "$1/$i" ]; then
      PERM_CUR=$(stat -f"%0Lp" "$1")
      PERM_NXT=$(stat -f"%0Lp" "$1/$i")
      GROUP_CUR=$(stat -f"%Sg" "$1")
      GROUP_NXT=$(stat -f"%Sg" "$1/$i")

      # Report on changing permissions
      if [[ $PERM_NXT -gt $PERM_CUR ]] ; then
        if [ "$1" == '/' ] ; then
          printf "PERMISSIONS;%s wider than %s going from %i to %i\n" "$i" "$1" "$PERM_CUR" "$PERM_NXT"
        else
          printf "PERMISSIONS;%s wider than %s going from %i to %i\n" "$1/$i" "$1" "$PERM_CUR" "$PERM_NXT"
        fi
      fi

      # Report on changing groups
      if [ "$GROUP_NXT" != "$GROUP_CUR" ] ; then
        if [ "$1" == '/' ] ; then
          printf "GROUPCHANGE;%s has another group, %s going from %s to %s\n" "$i" "$1" "$GROUP_CUR" "$GROUP_NXT"
        else
          printf "GROUPCHANGE;%s has another group, %s going from %s to %s\n" "$1/$i" "$1" "$GROUP_CUR" "$GROUP_NXT"
        fi
      fi

      # Call this function again until reaching maximum depth
      recurse_tree "$1/$i" "$2" | sed -r 's/^/\t/'
    #else
      # Uncomment to show files
      # echo "$i" | grep -E "$2"
    fi
  done
}

#
# Function: Remove trailing slash to improved directory printing
#
trailingslash() {
  if [ "$1" == '/' ] ; then
    STARTDIR="$1"
  else
    STARTDIR=$(echo "$1" | sed 's:/*$::')
  fi
}

#
# MAIN
#

# Exit if no argument
[ $# -eq 0 ] && echo "No starting directory given!" && exit 1

trailingslash "$1"
recurse_tree "$STARTDIR"
