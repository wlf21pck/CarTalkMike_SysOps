#!/bin/bash
#
# docroot-backup.sh
#

set -o pipefail

BUCKET="ombu-awscartalk-backup"

DIR="/www/backups/s3-sync/docroot"
TIME_EPOCH=$(perl -e "print time")
FILENAME="docroot-$TIME_EPOCH.tar.xz"
FILE="$DIR/$FILENAME"

TARCMD="/bin/tar --xz --create --file=$FILE --directory=/ --files-from -"

mkdir -p $DIR
cat <<EOF | sed -e 's/^\///' | $TARCMD
/www/docs
EOF

s3cmd put $FILE s3://$BUCKET/docroot/
s3cmd cp s3://$BUCKET/docroot/$FILENAME s3://$BUCKET/docroot/docroot-LATEST.tar.xz
rm -f $FILE

BACKUPS_TIMESTAMPS=$(s3cmd ls s3://$BUCKET/docroot/ | awk '{print $4}' | sed -n -r '/docroot-/s#.+docroot-([0-9]+)\.tar\.xz#\1# p')

# purge files that are too old
TIMESTAMP_BOUNDARY=$(( $TIME_EPOCH - 60 * 60 * 24 * 30 )) # 30 days
for BACKUP_TIMESTAMP in $BACKUPS_TIMESTAMPS; do
    if [ $BACKUP_TIMESTAMP -lt $TIMESTAMP_BOUNDARY ]; then
        s3cmd del s3://$BUCKET/docroot/docroot-$BACKUP_TIMESTAMP.tar.xz
    fi
done
