#!/bin/sh

bundle_exec=''

if [ -e Gemfile ]; then
	bundle install || exit 1
	bundle_exec="bundle exec"
fi

if ! $bundle_exec rake -T | grep -q '^rake spec '; then
	echo This validator needs a rake task called spec. 1>&2
	exit 1
fi
$bundle_exec rake spec
