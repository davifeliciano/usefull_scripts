#! /bin/bash
# Create a gzip compressed tarball of the directory
# given as the first CL argument. The file is created
# in the current working directory, and is encrypted
# using the gpg key supplied as the second CL argument.

if [ "$#" -ne 2 ]; then
	echo "Usage: $(basename $0) {directory to backup} {gpg key to use}"
	exit 1
fi

DIR_TO_BKP=$1
GPG_KEY="$2"
DIR_BASENAME=$(basename "$DIR_TO_BKP")

if [ ! -d "$DIR_TO_BKP" ]; then
	echo "First CL argument must be a dir. Try again."
	exit 1
fi

if [[ ! $(gpg --list-keys $GPG_KEY) ]]; then
	echo "Second CL argument must be a valid gpg key. Try again."
	exit 2
fi

OUTPUT_FORMAT=$"${DIR_BASENAME}_$(date +%d%m%y%H%M).backup"
ERR_LOG_FILE=$"$OUTPUT_FORMAT.err.log"
BYTES="$(du -sb "$DIR_TO_BKP" | cut -f1)"

function cleanup() {
	echo "Received SIGINT. Cleaning files."
	rm "$OUTPUT_FILE"
	exit 2
}

echo "Backing up $DIR_TO_BKP"
read -p "Use gzip compression? [yn] " USE_GZIP
trap "cleanup" SIGINT

case $USE_GZIP in
[yY]*)
	OUTPUT_FILE="$OUTPUT_FORMAT.tar.gz.gpg"
	tar -cf - "$DIR_TO_BKP" 2>"$ERR_LOG_FILE" |
		tqdm --bytes --total "$BYTES" --desc Progress --position 2 --mininterval 0.5 |
		gzip 2>"$ERR_LOG_FILE" |
		tqdm --bytes --desc Compressed --position 0 --mininterval 0.5 |
		gpg -er "$GPG_KEY" -o - 2>"$ERR_LOG_FILE" |
		tqdm --bytes --desc Encrypted --position 1 --mininterval 0.5 \
			>"$OUTPUT_FILE"
	;;

[nN]*)
	OUTPUT_FILE="$OUTPUT_FORMAT.tar.gpg"
	tar -cf - "$DIR_TO_BKP" 2>"$ERR_LOG_FILE" |
		tqdm --bytes --total "$BYTES" --desc Progress --position 1 --mininterval 0.5 |
		gpg -er "$GPG_KEY" -o - 2>"$ERR_LOG_FILE" |
		tqdm --bytes --desc Encrypted --position 0 --mininterval 0.5 \
			>"$OUTPUT_FILE"
	;;

*)
	echo "Invalid answer. Try again."
	exit 1
	;;
esac

echo "Error log saved to" $(basename $"$ERR_LOG_FILE")
echo "Backup saved to" $(basename $"$OUTPUT_FILE")
