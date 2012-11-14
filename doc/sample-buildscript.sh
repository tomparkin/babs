#!/bin/bash
#
# An example babs build script
#
# From babs' point of view, your build script needs to do two things:
#
#   1.  Build your project.  You should use the environmental variables that
#       babs provides (see below) to decide what to build and where to build
#       it.
#
#   2.  Generate a report.  The stdout and stderr streams from your build
#       script are treated by babs as a build report, which is included in the
#       email it sends to notify interested parties how your build is faring.
#       You can format the report however you wish.
#
# To make your build script's job slightly easier, babs provides information
# based on the build metadata you specified in babs.ini, and also sets up
# a build directory for you to check out and build in.  This build directory
# is persistent, so you may choose to log your checkout and build processes in
# the build directory, rather than spamming your build log with that
# information.
#
# Here is a summary of the environmental variables babs provides:
#
#   BABS_BUILD_TITLE
#       This is the title of the babs build as defined in babs.ini
#   
#   BABS_BRANCH_NAME
#       This is the branch name of the babs build as defined in babs.ini
#   
#   BABS_REVISION
#       This is the SCM revision your script should build
#   
#   BABS_BUILD_TARGET
#       This is the babs build target as defined in babs.ini
#   
#   BABS_WORKROOT
#       This is the build directory babs autogenerates for you to check out
#       and build your project in.  babs will cd your script into this
#       directory before it is executed.
