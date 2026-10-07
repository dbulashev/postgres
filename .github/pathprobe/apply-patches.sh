#!/bin/sh
# Apply the pathprobe core hooks patch on top of the checked-out tree.
#
# Usage: apply-patches.sh [--base-only] <pathprobe checkout>
#
# The patch is not copied into this repository: it is taken from the pathprobe
# checkout (patches/pathprobe-core-hooks.patch), so the hooks and the
# extension built against them always come from the same pathprobe commit.
#
# Local pathprobe changes: if .github/pathprobe/local-patches/ holds
# format-patch files, they are applied to the pathprobe checkout first, with
# git am, so that changes not yet in the pathprobe repository can be built and
# tested.  They come before the core hooks patch because they may change it.
#
# Prints the upstream commit the patch was applied to: the most recent commit
# that changes anything outside .github/.  The CI scaffolding on this branch
# lives entirely under .github/, so its commits are skipped whatever their
# subjects say.  With --base-only, prints the commit and applies nothing.
set -eu

base_only=false
if [ "${1:-}" = --base-only ]; then
	base_only=true
	shift
fi

top=$(git rev-parse --show-toplevel)
cd "$top"

base=$(git log -1 --format=%H -- . ':!.github')
# In a shallow clone the oldest fetched commit looks as if it added the whole
# tree, so it matches the pathspec even when the real base is deeper.
shallow="$(git rev-parse --git-dir)/shallow"
if [ -z "$base" ] || { [ -f "$shallow" ] && grep -qx "$base" "$shallow"; }; then
	echo "no upstream commit in the fetched history; increase fetch-depth" >&2
	exit 1
fi

if $base_only; then
	echo "$base"
	exit 0
fi

src=${1:?usage: apply-patches.sh [--base-only] <pathprobe checkout>}

set -- "$top"/.github/pathprobe/local-patches/*.patch
if [ -e "$1" ]; then
	git -C "$src" -c user.name=ci -c user.email=ci@localhost am "$@" >&2
fi

patch="$src/patches/pathprobe-core-hooks.patch"

# The patch is a plain diff, not a format-patch series: apply it to the
# working tree only.  Nothing is committed; the build context is the tree.
git apply --verbose "$patch" >&2

echo "$base"
