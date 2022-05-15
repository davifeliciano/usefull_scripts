#! /bin/bash
# Create a gzip compressed tarball of the directory
# given as the first CL argument. The file is created
# in the current working directory, and is encrypted
# using the gpg key supplied as the second CL argument.

DIR_TO_BKP="$1"
GPG_KEY="$2"

if [ ! -d "$DIR_TO_BKP" ]; then
  echo "First CL argument must be a dir. Try again."
  exit 1
fi

if [[ ! $(gpg --list-keys $GPG_KEY) ]]; then
  echo "Second CL argument must be a valid gpg key. Try again."
  exit 2
fi

OUTPUT_FORMAT="$(basename $DIR_TO_BKP)_$(date +%d%m%y%H%M).backup"
ERR_LOG_FILE="$OUTPUT_FORMAT.err.log"
OUTPUT_FILE="$(pwd)/$OUTPUT_FORMAT.tar.gz.gpg"
BYTES="$(du -sb "$DIR_TO_BKP" | cut -f1)"

function remove_files ()
{
  echo "Received SIGINT. Cleaning files."
  rm "$OUTPUT_FILE"
  exit 2
}

trap "remove_files" SIGINT
tar -cf - "$DIR_TO_BKP" 2> "$ERR_LOG_FILE" \
  | tqdm --bytes --total "$BYTES" --desc Progress --position 2 --mininterval 0.5 \
  | gzip \
  | tqdm --bytes --desc Compressed --position 0 --mininterval 0.5 \
  | gpg -er "$GPG_KEY" -o - \
  | tqdm --bytes --desc Encrypted --position 1 --mininterval 0.5 \
  > "$OUTPUT_FILE" 

echo "Error log saved to $(basename $ERR_LOG_FILE)"
echo "Backup saved to $(basename $OUTPUT_FILE)"