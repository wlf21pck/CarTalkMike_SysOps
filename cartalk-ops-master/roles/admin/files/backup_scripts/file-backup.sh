#!/bin/bash
#
# file-backup.sh
#

set -o pipefail

BUCKET="ombu-awscartalk-backup"

DIR="/www/backups/s3-sync/files"
FILE="$DIR/files.tar.xz"

TARCMD="/bin/tar --xz --create --file=$FILE --directory=/ --files-from -"

mkdir -p $DIR
cat <<EOF | sed -e 's/^\///' | $TARCMD
/etc/passwd
/etc/shadow
/etc/group
/etc/hosts
/var/spool/cron
/etc/sysconfig
/etc/httpd/conf
/etc/httpd/conf.d
/www/backups/scripts
EOF

# GFS-Rotate
/www/backups/scripts-sync/gfs-rotate -m 3 -w 5 -d 7 $FILE

s3cmd sync --delete-removed $DIR/ s3://$BUCKET/files/
