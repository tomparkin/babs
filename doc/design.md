babs design
===========

babs is a distributed continuous integration build system based on Bash and
SSH.  The lower-level interfaces and library scripts are designed to be
reusable as the basis for other distributed systems.

This document briefly describes babs' design.

A distributed build farm
------------------------

While babs can run on a single machine, it is designed to utilise a farm of
build machines.  Within the build farm, a master/slave model is used for
the distribution of jobs within the system.  This works as follows.

One machine in the build farm is designated as a master.  It runs the main babs
script.  This machine stores the babs configuration file which details the
projects to be built, and is responsible for managing the process of running
these builds.  To do this, the master periodically scans the SCM system for
updates.  When it detects a change in a tree it is monitoring, it asks one of
the slave machines to run a build job for the updated tree.  Once the slave
has completed the job, the master will optionally send out a status email reporting
the status of the build.

Since all the babs configuration information and SCM-tracking logic runs
on the master machine, the slave machines are very simple.  Each machine runs
the babs jobrunner script, which does nothing but wait for a job to run.  As
jobs arrive, the jobrunner executes them in order, and reports back to the master.

Communications between master and slave machines is carried out over SSH.
Password-less SSH keys are used to allow this to be done automatically.

Infrastructure primatives
-------------------------

Although this codebase implements an autobuilder, the core infrastructure
is reusable for other tasks.  This infrastructure consists of a number of
core "primative" components:

 *  Queues.  A fifo-style queue of arbitrary lines of text, with locking
    functions to provide serialised access to the underlying data.

 *  Lists.  An indexed list of aribtrary textual data based on queues.

 *  Events.  Methods based on queues to provide event generation and
    consumption.

These are implemented as Bash library scripts.  The underlying data storage
backend is the filesystem, with locking implmented using lockfiles in
combination with Bash's "noclobber" option.  Non-busy blocking on events is
implemented using inotify.

Code hierarchy
--------------

The build farm consists of the following files:

 *  libqueue.sh: library script implementing queues.

 *  liblist.sh: library script implementing lists.

 *  libevent.sh: library script implementing events.

 *  libini.sh: library script for parsing .ini configuration files[1].

 *  libjob.sh: library script implementing a shared format for job specification.
    A "job" consists of a script to be run, the IP of the host that script is
    stored on, a report script, and the IP of the host the report script is
    stored on.

 *  liblog.sh: library script providing logging functions.

 *  libpmrpc.sh: library script providing "Poor Man's RPC" functions, a wrapper around SSH.

 *  libreport.sh: library script used for generating build reports.

 *  libutil.sh: miscellaneous utility functions.

 *  libautobuilder.sh: autobuilder library, moved from the main script for clarity.

 *  babs: the main babs script

 *  jobrunner: generic job execution script that is used on the build farm slaves.


Configuration
-------------

babs is configured using an .ini file which contains information about:

 * the pool of slave machines in the build farm
 * the various projects to be monitored for changes

An example file is provided which details all the configuration options.

In order to build each project, the user provides a script which carries out whatever
tasks they wish.  Again, an example build script (for the babs project) gives pointers
on how to implement this script for your project.
