Installation
------------

On the master machine:

   1. Install babs, inotify-tools, ssh server, and msmtp for email.

   2. Ensure the master has password-free SSH keys for each of the slaves
      in the build farm pool.  The master will log in as the user running
      the autobuilder script.

   3. Edit the babs configuration file /etc/babs/babs.ini.  The comments
      in the file detail the configuration options.

On each slave machine:
 
   1. Install babs, inotify-tools, and ssh server.

   2. Ensure each slave has password-free SSH keys for the master machine.
      The slave will log in as the user running the jobrunner script.

Running
-------

On the master:

   1. Run the babs process:

      /usr/bin/babs run

   2. Arrange for something (e.g. cron job) to periodically generate an SCM
      scan event:

      /usr/bin/babs scan

On each slave:

   1. Run the jobrunner process:

      /usr/bin/jobrunner run


Once the system is up and running you can request information from
babs by running various commands.  The "-h" argument to prints usage
information.
