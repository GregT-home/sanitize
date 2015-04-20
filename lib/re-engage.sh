#!/bin/bash
#
# re-engage.sh
#
script_name=$(basename $0)
Usage="
$0:
  Usage: $script_name [--safe] <remote-repo> <target-dir>

  Will effectively git clone the specified remote-repo into the target
  non-git controlled directory, leaving all files existing before the
  cloning as uncontrolled files.  The target cannot be the current
  directory.

  options:
    --safe  stop short of replacing the target directory and leave the 
            temporary directory containing the re-engaged contents.
"
Help="?${script_name}: --help for operation summary."

function echo_error() {
  echo 1>&2 "$@"
}

function echo_error_help() {
  echo_error "$@"
  echo_error "$Help"
}

tmp_prefix="./tmp.$$"
tmp_dir="$tmp_prefix.re-engage.repo.d"
tmp_tarfile="./tmp.$$.re-engage.tarfile.tgz"

# Process command line
safe_option="no"
remote_repo=
target_dir=
while true
do
  case $# in
    0) break ;;
  esac

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
        2)
          remote_repo="$1"
          shift
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

case $remote_repo in
  "")
    echo_error_help "?No remote repository specified"
    exit 1
esac

case $target_dir in
  "")
    echo_error_help "?No target directory specified"
    exit 1
esac

test -d $target_dir || {
  echo_error_help "?target directory not found: $target_dir"
  exit 1
}

test -d $target_dir/.git && {
  echo_error_help "?.git directory found. Cannot re-engage into a git-controlled directory: $target_dir"
  exit 1
}

this_dir=$(cd .; pwd)
case $(cd $target_dir; pwd) in
  $this_dir)
    echo_error_help "?target directory cannot be current directory"
    exit 1
    ;;
esac

mkdir $tmp_dir || {
  echo_error_help "?Unable to create temporary directory ($tmp_dir)"
  exit 1
}

git clone $remote_repo $tmp_dir || {
  echo_error_help "?Unable to clone specified repository: $remote_repo. $Help"
  exit 1
}

(cd $target_dir; tar czf - ./) | tar xzfC - $tmp_dir || {
  echo_error_help "?Unable to copy source directory. $Usage"
  exit 1
}

case $safe_option in
  yes)
    echo_error_help "[Safe Mode] tmp_dir ($tmp_dir) should now be re-engaged, target_dir is unchanged."
    exit 0
    ;;

  no)
    mv $target_dir $tmp_prefix.$starting_dir
    mv $tmp_dir $target_dir
    rm -rf $tmp_prefix.$starting_dir
    ;;
esac

echo "Target directory has been re-engaged with $remote_repo"
