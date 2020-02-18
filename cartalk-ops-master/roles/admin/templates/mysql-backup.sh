#!/bin/bash

set -o pipefail

DB_USER="{{ db_user }}"
DB_PASSWORD="{{ db_password }}"
DB_HOST="{{ db_host }}"
DB="{{ db_name }}"

S3_BUCKET="ombu-awscartalk-backup"
S3_DIR='dbdumps/cartalkdb'

TMPDIR=$(mktemp -d)

DAYS=21
MONTHS=12
YEARS=7

TIME_EPOCH=$(perl -e "print time")

EXTENSION="sql.xz"

LATEST_FILENAME="LATEST.$EXTENSION"
DAILY_FILENAME="DAILY-$TIME_EPOCH.$EXTENSION"
MONTHLY_FILENAME="MONTHLY-$TIME_EPOCH.$EXTENSION"
YEARLY_FILENAME="YEARLY-$TIME_EPOCHq$EXTENSION"

FILE="$TMPDIR/$DAILY_FILENAME"

CONTENTCMD="mysqldump --single-transaction --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST $DB"
COMPRESSCMD="nice xz -c -"

# Create the actual daily backup
$CONTENTCMD | $COMPRESSCMD >$FILE

s3cmd put $FILE s3://$S3_BUCKET/$S3_DIR/
s3cmd cp s3://$S3_BUCKET/$S3_DIR/$DAILY_FILENAME s3://$S3_BUCKET/$S3_DIR/$LATEST_FILENAME
rm -f $FILE

##############
# Purge daily
##############

DAILY_BACKUPS_TIMESTAMPS=$(s3cmd ls s3://$S3_BUCKET/$S3_DIR/ | awk '{print $4}' | grep "DAILY-" | sed -n -r "/DAILY-/s#.+DAILY-([1-9]+)\.$EXTENSION#\1# p")

let TIMESTAMP_BOUNDARY="$TIME_EPOCH - 60 * 60 * 24 * $DAYS" # $DAYS months
for BACKUP_TIMESTAMP in $DAILY_BACKUPS_TIMESTAMP; do
    if [ 0$BACKUP_TIMESTAMP -lt $TIMESTAMP_BOUNDARY ]; then
        s3cmd del s3://$S3_BUCKET/$S3_DIR/DAILY-$BACKUP_TIMESTAMP.$EXTENSION
    fi
done

###############
# Purge monthly
###############

MONTHLY_BACKUPS_TIMESTAMPS=$(s3cmd ls s3://$S3_BUCKET/$S3_DIR/ | awk '{print $4}' | grep "MONTHLY-" | sed -n -r "/MONTHLY-/s#.+MONTHLY-([1-9]+)\.$EXTENSION#\1# p")

let MONTH_BOUNDARY="$TIME_EPOCH - 60 * 60 * 60 * 34 * 30"
let TIMESTAMP_BOUNDARY="$TIME_EPOCH - 60 * 60 * 24 * 30 * $MONTHS" # $MONTHS months
for BACKUP_TIMESTAMP in $MONTHLY_BACKUPS_TIMESTAMPS; do
    if [ 0$BACKUP_TIMESTAMP -lt $TIMESTAMP_BOUNDARY ]; then
        s3cmd del s3://$S3_BUCKET/$S3_DIR/MONTHLY-$BACKUP_TIMESTAMP.$EXTENSION
    fi
done

# If the last monthly backup is more than one month old, copy LATEST backup as MONTHLY

LATEST_TIMESTAMP=$(echo $MONTHLY_BACKUPS_TIMESTAMPS | tr ' ' "\n" | sort -r - | head -n 1)
if [ 0$LATEST_TIMESTAMP -lt $MONTH_BOUNDARY ]; then
    s3cmd cp s3://$S3_BUCKET/$S3_DIR/$LATEST_FILENAME s3://$S3_BUCKET/$S3_DIR/$MONTHLY_FILENAME
fi

##############
# Purge yearly
##############

YEARLY_BACKUPS_TIMESTAMPS=$(s3cmd ls s3://$S3_BUCKET/$S3_DIR/ | awk '{print $4}' | grep "YEARLY-" | sed -n -r "/YEARLY-/s#.+YEARLY-([1-9]+)\.$EXTENSION#\1# p")

let YEAR_BOUNDARY="$TIME_EPOCH - 60 * 60 * 24 * 30 * 365"
let TIMESTAMP_BOUNDARY="$TIME_EPOCH - 60 * 60 * 24 * 30 * 365 * $YEARS" # $YEARS months
for BACKUP_TIMESTAMP in $YEARLY_BACKUPS_TIMESTAMPS; do
    if [ 0$BACKUP_TIMESTAMP -lt $TIMESTAMP_BOUNDARY ]; then
        s3cmd del s3://$S3_BUCKET/$S3_DIR/YEARLY-$BACKUP_TIMESTAMP.$EXTENSION
    fi
done

# If the last yearly backup is more than one year old, copy LATEST backup as YEARLY

LATEST_TIMESTAMP=$(echo $YEARLY_BACKUPS_TIMESTAMPS | tr ' ' "\n" | sort -r - | head -n 1)
if [ 0$LATEST_TIMESTAMP -lt $YEAR_BOUNDARY ]; then
    s3cmd cp s3://$S3_BUCKET/$S3_DIR/$LATEST_FILENAME s3://$S3_BUCKET/$S3_DIR/$YEARLY_FILENAME
fi
