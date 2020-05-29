#/bin/bash
set -e
set -x

# Require noahdev's tbd, --ignore-weak-defs option was added in https://github.com/DGh0st/tbd fork (original version available https://github.com/inoahdev/tbd)
# Converts a mach-o into a tbd (Create a tbd for HSWidgets for linking subprojects or custom widgets)
#
#	TBD_INPUT_PATH := input path of the mach-o file to convert
#	TBD_OUTPUT_PATH := output path to generate the tbd file at
#
tbd -p --ignore-weak-defs --ignore-undefineds --ignore-flags --ignore-uuids $TBD_INPUT_PATH -o $TBD_OUTPUT_PATH
