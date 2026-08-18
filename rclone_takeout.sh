#!/bin/bash

# Example config for rclone_takeout.sh
# export RCLONE_TAKEOUT_REMOTE_PATH="drive:Takeout"
# export RCLONE_TAKEOUT_OUTDIR="~/takeout"
# export RCLONE_TAKEOUT_GPG_RECIPIENT="A1B2C3D4"
# export RCLONE_TAKEOUT_CONCURRENCY=10

required_vars=(
    "RCLONE_TAKEOUT_REMOTE_PATH"
    "RCLONE_TAKEOUT_OUTDIR"
    "RCLONE_TAKEOUT_GPG_RECIPIENT"
    "RCLONE_TAKEOUT_CONCURRENCY"
)

missing=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing+=("$var")
    fi
done

if (( ${#missing[@]} > 0 )); then
    echo "Error: missing required environment variable(s): ${missing[*]}" >&2
    exit 1
fi

echo "Starting backup process with the following configurations:"
echo
echo "    RCLONE_TAKEOUT_REMOTE_PATH: $RCLONE_TAKEOUT_REMOTE_PATH"
echo "    RCLONE_TAKEOUT_OUTDIR: $RCLONE_TAKEOUT_OUTDIR"
echo "    RCLONE_TAKEOUT_GPG_RECIPIENT: $RCLONE_TAKEOUT_GPG_RECIPIENT"
echo "    RCLONE_TAKEOUT_CONCURRENCY: $RCLONE_TAKEOUT_CONCURRENCY"
echo

outdir="$RCLONE_TAKEOUT_OUTDIR/rclone_takeout_$(date +%Y%m%d%H%M%S)"

echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Creating directory $outdir"
mkdir -p "$outdir"

rclone lsf "$RCLONE_TAKEOUT_REMOTE_PATH" --files-only | \
xargs -d "\n" -I {} -P "$RCLONE_TAKEOUT_CONCURRENCY" bash -c '
    set -o pipefail

    log() {
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1"
    }

    outdir="$1"
    file="$2"
    encrypted_file="${outdir}/${file}.gpg"

    log "Downloading and encrypting $file"

    if rclone cat "$RCLONE_TAKEOUT_REMOTE_PATH/$file" | gpg --batch --yes -er "$RCLONE_TAKEOUT_GPG_RECIPIENT" -o "$encrypted_file"; then
        log "File $file saved and encrypted successfully"
    else
        log "Failed to process $file. Removing it."
        rm -f "$encrypted_file"
    fi
' _ $outdir {}

echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Successfully completed backup process. All files are saved in $outdir"
