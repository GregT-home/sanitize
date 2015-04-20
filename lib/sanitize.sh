#!/bin/bash
#
# sanitize.sh
#
script_name=$(basename $0)
Usage="
$0:
  Usage: $script_name [options] target-dir

  This script will delete all git-controlled files and related git
  directory from the target-dir.

  It will flag an error and take no action if:
   - the directory is not git controlled
   - the work tree contains any tracked files
   - the local repo contains any stashed changes
   - there are any un-pushed commits present

  target-dir cannot be the current directory.

  options:
     --safe  run through the script but do not perform the 
             actual deletions.
"
Help="?${script_name}: --help for operation summary."

function echo_error() {
  echo 1>&2 "$@"
}

function echo_error_help() {
  echo_error "$@"
  echo_error "$Help"
}

# Process command line
safe_option="no"
target_dir=
while true
do
  # No more arguments? Done.
  case $# in
    0) break ;;
  esac

  # option processing
  case $1 in
    --safe|--s*)
      safe_option="yes"
      ;;

    --help|-h*)
      echo_error "$Usage"
      exit 1
      ;;

     -*)
       echo_error_help "?Invalid option: $1"
       exit 1
       ;;

      *)
       case $# in
         1)
           target_dir="$1"
           ;;

         *)
           echo_error_help "?Wrong number of arguments."
           exit 1
           ;;
       esac
       ;;
  esac
  shift
done

case $target_dir in
  "")
    echo_error_help "?No target directory specified."
    exit 1
    ;;
esac

test -d $target_dir || {
  echo_error_help "?target directory not found: $target_dir"
  exit 1
}

this_dir=$(cd .; pwd)
case $(cd $target_dir; pwd) in
  $this_dir)
    echo_error_help "?target directory cannot be current directory."
    exit 1
    ;;
esac

test ! -d $target_dir/.git && {
  echo_error_help "?Not git controlled: $target_dir/.git directory not found."
  exit 1
}

grep --silent "[[:space:]]*remote[[:space:]]*=" $target_dir/.git/config || {
  echo_error_help "?Aborting. $target_dir git repository has no remotes."
  exit 1
}

(cd $target_dir; git status --porcelain) | grep -v --silent "??" && {
  echo_error_help "?$target_dir working directory contains uncommitted changes. Please save your changes or remove them from the working directory."
  exit 1
}

(cd $target_dir; test $(git stash list | wc -l) -gt 0) && {
  echo_error_help "?$target_dir local repo has stashed changes.  Please save your changes or remove them from the repo."
  exit 1
}

num_unpushed_files=$(cd $target_dir; git cherry -v 2> /dev/null | wc -l)
if test $num_unpushed_files -gt 0
then
  echo_error_help "?Aborting.  There is an unpushed commit in the $target_dir repository."
  exit 1
fi

case $safe_option in
  y*)
    protect_action="echo [Safe Mode]"
    ;;
esac

${protect_action} && (cd $target_dir; rm -f `git ls-files`) || {
  echo_error_help "?File deletion failed in $target_dir.  Aborting before deleting .git directory."
  exit 1
}

${protect_action} && (cd $target_dir; rm -rf .git) || {
  echo_error_help "?Deletion of $target_dir/.git directory failed.  Resulting local repository may be corrupt."
  exit 1
}

echo "Directory has been ${protect_action}sanitized: $target_dir"
