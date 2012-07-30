keizoku
=======

Lightweight CI scripts for git

Installation
------------

* Install the keizoku gem on the host to which updates will be pushed
  (for simple use cases, your "origin" server)
* Create a directory that can be used to store the queued requests.
  This directory will also be used by the cron to store logfiles and a
  lockfile.
* Navigate to the bare version of your repo (i.e. the repo to which
  you push when you push to "origin")
* From the root of the bare repo, run kerberos-init.
  + It will ask you for the URL for the repo. This will be used to
    clone the repo as well as to commit the merges into the workbench
    branch, so read and write acces is required.
  + It will ask for the path to the directory that will be used to
    store the queued requests.
  + Once it has done that, it will generate a post-receive hook, a
    post-receive.conf file and a keizoku-cronjob file in your repo's
    hooks directory.
* Setup a crontab entry to run the keizoku-cronjob as often as you
    like.

Using Keizoku
-------------

* Create a workbench branch (this is the branch into which validated
  changes will be merged) - e.g. workbench\_sprint\_999. The branch
  name should include the word "workbench"
* Checkout this branch in your working copy of the repo
* Branch off your workbench branch into a private branch - this will
  be the branch in which you make all your code changes - the name
  should contain the name of your workbench branch and should be prefixed
  with "ci" e.g. "ci\_awesome\_stuff\_for\_workbench\_sprint\_999"
* Commit and push and go crazy :)
* When you have pushed a commit that you want to integrate - apply a tag
  to your last commit:
  + The tag should be of the form ci\_localpartofemailaddress\_some\_nonsense
  e.g. if your email address is bibbity@bobbity.zzz, then your tag name
  should be of the form: ci\_bibbity\_the\_rest\_does\_not\_matter
  + Add a message to the tag - this will be the commit message used by
  Keizoku if it merges the commit into the workbench branch.
* git push --tags
* If the integration is successful, Keizoku will make a squashed merge
  into the workbench branch.
* The default notifier writes entries to .keizoku-cronjob.log which is
  in the specified queue directory.

Current limitations
-------------------

* Not tested with RVM.
* Ruby 1.9 only (no plans to suport 1.8).
* Operates as a git hook installed on the repository server (so not Github
  support).
* The git hook must have rubygems' "EXECUTABLE DIRECTORY" in its PATH.
* The cron job that dispatches integration requests must run on the git server,
  although custom integration scripts and validation scripts could farm those
  tasks out to other servers.
* The cron job must have rubygems' "EXECUTABLE DIRECTORY" in its PATH.
* The only validator supported out of the box is "rake spec" (with optional
  bundler support).
* The rake gem must be installed.
* The bundler gem must be installed for projects that use bundler.
