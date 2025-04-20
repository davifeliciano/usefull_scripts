#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: $(basename $0) {GPG_KEY}"
	exit 1
fi

timestamp=$(ls -1 | grep -oP '(?<=takeout\-)(\d{8}T\d{6}Z)(?=\-\d{3}.tgz)' | sort -u)
timestamps_found=$(echo "$timestamp" | wc -l)
output_file="takeout-$timestamp.tgz.gpg"

if [ -f "$output_file" ]; then
	echo "File $output_file already exists. Exiting..."
	exit 2
fi

if [ "$timestamps_found" -gt 1 ]; then
	echo "Google Takeout files with mixed timestamps found. Exiting..."
	exit 2
fi

if [ -z "$timestamp" ]; then
	echo "No Google Takeout files found. Exiting..."
	exit 2
fi

echo "Found Google Takeout files with timestamp $timestamp"
fifo=$(mktemp -u --suffix .bkp_takeout)
mkfifo "$fifo" || { echo "Failed to create named pipe at $fifo"; exit 3; }
echo "Created named pipe at $fifo"

cleanup() {
    if [ -p "$fifo" ]; then
        echo "Removing named pipe at $fifo"
        rm -f "$fifo"
    fi
}

trap "cleanup" EXIT
trap "cleanup" SIGINT
trap "cleanup" SIGTERM
trap "cleanup" SIGHUP
trap "cleanup" SIGQUIT

cat takeout-$timestamp-*.tgz >"$fifo" & cat_pid=$!
gpg -er "$1" -o "$output_file" -z 0 <"$fifo" &
progress -mp $cat_pid
echo "Done! Files encrypted to $output_file"