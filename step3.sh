#!/bin/bash

# This step creates an image that includes MicroShift 4.13. Its parent
# is set to the rhel-9.2 image created in step1.sh, but the ref is set
# to a different value. It also creates an alias ref to make it easy
# to examine that image after the update is created.

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

# Add sources for MicroShift dependencies
sudo composer-cli sources add fast-datapath-rhel9.toml
sudo composer-cli sources add rhocp-4.13.toml

# Build an image with MicroShift 4.13
sudo composer-cli blueprints push rhel92-ms413.toml
sudo composer-cli blueprints depsolve rhel-9.2-microshift-4.13
build_id=$(sudo composer-cli compose start-ostree \
                --ref rhel/9.2/x86_64/edge-ms \
                --parent rhel/9.2/x86_64/edge \
                --url http://localhost:8080/repo \
                rhel-9.2-microshift-4.13 \
                edge-commit | awk '{print $2}')
waitfor_image "${build_id}"

# Download the image and unpack it into a local repository
sudo composer-cli compose image "${build_id}"
sudo chown -R "$(whoami)". *.tar
tar -xf "${build_id}-commit.tar"

# Update the metadata in the repo
ostree summary --update --repo=repo

# Create the alias for step 3
ostree refs --repo=repo rhel/9.2/x86_64/edge-ms --create=step3 --alias --force

# List the contents of the image
ostree ls --repo=repo rhel/9.2/x86_64/edge-ms

./show.sh
