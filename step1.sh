#!/bin/bash

# This script builds an initial RHEL 9.2 image without any special contents.

set -e -o pipefail

waitfor_image() {
    local uuid=$1

    local -r tstart=$(date +%s)
    echo "$(date +'%Y-%m-%d %H:%M:%S') STARTED"

    local status
    status=$(sudo composer-cli compose status | grep "${uuid}" | awk '{print $2}')
    while [[ "${status}" = "RUNNING" ]] || [[ "${status}" = "WAITING" ]]; do
        sleep 20
        status=$(sudo composer-cli compose status | grep "${uuid}" | awk '{print $2}')
        echo "$(date +'%Y-%m-%d %H:%M:%S') ${status}"
    done

    local -r tend=$(date +%s)
    echo "$(date +'%Y-%m-%d %H:%M:%S') ${status} - elapsed $(( (tend - tstart) / 60 )) minutes"

    if [ "${status}" = "FAILED" ]; then
        echo "Blueprint build has failed. For more information, review the downloaded logs"
        exit 1
    fi
}

sudo composer-cli sources list

# Build a basic RHEL 9.2 image
sudo composer-cli blueprints push rhel92.toml
sudo composer-cli blueprints depsolve rhel-9.2
build_id=$(sudo composer-cli compose start-ostree --ref rhel/9.2/x86_64/edge rhel-9.2 edge-commit | awk '{print $2}')
waitfor_image "${build_id}"

# Download the image and unpack it into a local repository
sudo composer-cli compose image "${build_id}"
sudo chown -R "$(whoami)". *.tar
tar -xf "${build_id}-commit.tar"

# Update the metadata in the repo
ostree summary --update --repo=repo

# Create the alias for step 1
ostree refs --repo=repo rhel/9.2/x86_64/edge --create=step1 --force

./show.sh
