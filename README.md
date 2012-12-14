The Bash-based Build Server (babs)
==================================

babs is a
[Continuous Integration](http://www.martinfowler.com/articles/continuousIntegration.html)
style autobuilder implemented as a set of Bash scripts.

Features
--------

 * Minimal requirements.  babs should run happily anywhere that Bash, SSH,
   inotify-tools, and mstmp are available.
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

License
-------

babs is released under the MIT/BSD license:

Copyright © 2012 Tom Parkin. All Rights Reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY Tom Parkin "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
