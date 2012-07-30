keizoku
=======

Lightweight CI scripts for git

Current limitations
-------------------

* Not tested with RVM.
* Ruby 1.9 only (no plans to suport 1.8).
* Operates as a git hook installed on the repository server (so not Github
  support).
* The git hook must have rubygems' "EXECUTABLE DIRECTORY" in its PATH.
* The only validator supported out of the box is "rake spec" (with optional
  bundler support).
* The rake gem must be installed.
* The bundler gem must be installed for projects that use bundler.
* The cron job that dispatches integration requests must run on the git server,
  although custom integration scripts and validation scripts could farm those
  tasks out to other servers.
* The cron job must have rubygems' "EXECUTABLE DIRECTORY" in its PATH.
