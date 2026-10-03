#!/bin/sh
# Apply the planner path-pruning injection point series on top of the
# checked-out tree.  The patches are copies of
# experiments/ch08-path-probe/hackers/000[123]-*.patch from the
# running-postgresql repository; refresh them there first, then copy.
#
# Prints the upstream commit the series was applied to: the first ancestor
# whose subject does not start with "path-probe:".  Every commit of the CI
# scaffolding on this branch must carry that prefix.  With --base-only, prints
# the commit and applies nothing.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
top=$(git rev-parse --show-toplevel)
cd "$top"

base=$(git log --format='%H %s' | awk '$2 != "path-probe:" { print $1; exit }')
if [ -z "$base" ]; then
	echo "no upstream commit in the fetched history; increase fetch-depth" >&2
	exit 1
fi

if [ "${1:-}" = --base-only ]; then
	echo "$base"
	exit 0
fi

git -c user.name=ci -c user.email=ci@localhost \
	am --3way "$here"/patches/*.patch >&2

echo "$base"
