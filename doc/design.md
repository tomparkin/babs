babs design
===========

babs is a distributed continuous integration build system based on Bash and 
SSH.  The lower-level interfaces and library scripts are designed to be 
reusable as the basis for other distributed systems.

This document briefly describes babs' design.

The build farm
--------------

A master/slave model is used for distributing jobs in the system.

The master stores configuration for the projects being built, checks
the SCM for project updates, and passes build jobs out to the slave
machines.  When the slave machines have completed their jobs the master
is further responsible for sending status emails out to the project teams.

The slave(s) store no project-specific information.  Their sole role
is to accept jobs from the master, execute them, and return a response.
The nature of the job and the response is entirely dictated by the master,
to the extent that the slave(s) could conceivably be used to execute any
aribtrary job on the master's behalf.

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

The build farm is configured using:

 *  A toplevel .ini file[1] containing information about the
    slave machines in the build pool, and the project trees to
    monitor and build.  An example file, autobuilder.ini, provides
    documentation of all the options, as well as project specification
    examples for C672, dimiter, and D183.

 *  Per-project build scripts which handle the process of building that
    project.  Common tasks such as changelog generation or checkout caching
    have been abstracted into "libreport.sh", which is combined with the
    project-specific script by the autobuilder at runtime.

REFERENCES
----------

[1].  http://en.wikipedia.org/wiki/INI_file

[2].  http://www.thesecretdogproject.com/2011/12/of-build-farms-and-bash-queues/
