The Bash-based Build Server (babs)
==================================

babs is a
[Continuous Integration](http://www.martinfowler.com/articles/continuousIntegration.html)
style autobuilder implemented as a set of Bash scripts.

Features
--------

 * Minimal requirements.  babs should run happily anywhere that Bash, SSH, and
   inotify-tools are available.
 * Build farm support.  babs uses a central-server model to hand jobs off to
   any of an arbitrary number of build machines.  Load is balanced across the
   farm by passing new jobs to the least-busy available slave.
 * Multiple projects.  babs can monitor an arbitrary number of projects for
   changes.
 * Build anything.  babs doesn't care what you use to build your project --
   you simply provide a per-project build script (in Bash, naturally), which
   carries out whatever build tasks you need.
 * Flexible configuration file.  All babs' configuration lives in a single
   .ini file installed on the central server.

Why another build server
------------------------

I wrote babs as a quick hack to fill an immediate need.  We had a pool of
powerful build machines that we being poorly utilised due to an ad-hoc
approach to a CI process.  We clearly needed a proper build server, and yet
a proper solution using something along the lines of Jenkins had been "in
progress" for too long.  My short-term solution to this was babs -- a tool
which would share the build load effectively without requiring a lot of
installation or configuration work.

After that, I worked on babs because it just seemed like fun to write a
distributed build server in Bash.
