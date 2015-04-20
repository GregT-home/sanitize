# Overview

This suite of scripts can be used when you want to remove all local files belonging to a client prior to an extended absence. 

# Installation

The scripts are self contained and executable.  You can copy them to your local 'bin' directory and use the script names to invoke them, or clone the development directory and add a 'bash' alias to put them into your environment.

 There are currently two scripts that are part of this package:

**sanitize.sh [--help | --safe] \<target-dir>**
- Deletes all git-controlled files and related git meta-data in the target directory, leaving the directory hierarchy and uncontrolled files.

**re-engage.sh [--help | --safe] \<remote-git-repo> <target-dir>**
- Restores the specified git repo to the target directory, preserving all files already in the existing hierarchy

In both scripts, the `--help` option will display a usage message and the  `--safe` option will skip destructive operations, but may leave intermediate results behind for examination and manual deletion.


# Theory of Operation

Because potentially critical code files are being destroyed, operation has been structured to minimize the possibility that unique information is totally lost due to interrupt or error.

In particular, `sanitize.sh` gives precedence to files you had in your target directory prior to its being sanitized.  This is to eliminate the possibility that unique work gets lost in a re-engagement.

Example: if you have an untracked file `new_idea.rb` which is not in the remote repo and you sanitize your working directory, that file is retained in your sanitized directory. When you return, if you re-engage with the repo and someone has written another version of the `new_idea.rb` file, then your change will overwrite that version and a `git status` would show this. If you decide the file written while you were away is the better choice, you can check it out and overwrite your own version. But if the git repo info had overwritten your version and you decided your version was better, then you would have no way of recovering the overwritten changes.

# Testing

Use the following commands to run tests for each script:

`./test/sanitize_test.sh --live [--help | --verbose | --safe]`

`./test/re-engage_test.sh --live [--help | --verbose | --safe]`

Since these scripts manipulate source code directories, they require the mandatory switch, `--live` in order to run.  Invoking with no arguments will result in an error.

Options:
* `--help`  Display a usage message.
* `--save`  pass the ``--safe`` option to the commands being tested.
* `--verbose`  display a bit more intermediate information and pause after each test to all an interactive examination of the current test results.  When paused, it is possible to suspend the test script using `^Z` to look at intermediate results.  Use `fg` to resume operation.  It is also, of course, possible to abort test operation with `^C`.




