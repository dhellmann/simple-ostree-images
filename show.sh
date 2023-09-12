#!/bin/bash

set -e -o pipefail

title() {
    echo
    echo -e "\E[34m\n# $1\E[00m"
}

# Show the summary of the repo
title "ostree summary --view"
ostree summary --view --repo=repo

title "ostree refs --list --revision"
ostree refs --repo=repo --list --revision

for ref in $(ostree refs --repo=repo --list); do
    title "ostree log ${ref}"
    ostree log --repo=repo "${ref}"

    # List the contents of the image
    title "ostree ls ${ref}"
    ostree ls --repo=repo "${ref}"
done
