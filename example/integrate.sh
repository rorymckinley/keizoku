#!/bin/sh -ex
#
# Supplied environment variables:
#
# WORKBENCH
# TAGGERNAME
# TAGGEREMAIL
# COMMIT
# TAG
# REPO

validate=$(readlink -f "$(dirname $0)/validate.sh")

base=$(mktemp -d -t keizoku-integrate.XXXXXXXXXX) || exit 1
message=$(mktemp -t keizoku-message.XXXXXXXXXX) || exit 1

cleanup() {
	cd /
	[ -n "${base}" ] && rm -rf ${base}
	[ -n "${message}" ] && rm -rf ${message}
}
trap cleanup SIGHUP SIGINT SIGTERM

git clone ${REPO} ${base}/work
cd ${base}/work
git checkout -t -b ${WORKBENCH} origin/${WORKBENCH}
git for-each-ref --format='%(contents)' ${TAG} > ${message}
git merge --squash ${COMMIT}

if ! ${validate}; then
	cleanup
	exit 1
fi

git commit -F ${message} --author="${TAGGERNAME} ${TAGGEREMAIL}"
git push
cleanup
exit 0
