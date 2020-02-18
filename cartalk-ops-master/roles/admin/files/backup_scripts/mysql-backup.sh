#!/bin/bash

set -o pipefail

BUCKET="ombu-awscartalk-backup"

DIR="/www/backups/s3-sync/dbdumps"
USER="backup"
PASS="back1tup"
#SERVER="awscartalkdb01.cartalk.com"
SERVER="awscartalkdb01-vpc.cartalk.com"
DAYS=7

DATABASE="cartalkdb"
#DBCMD=mysql -h$SERVER -u$USER -p$PASS
#NOW=`date +%Y%m%d-%H%M-`

for db in $DATABASE
do
        if [ ! -d $DIR/$db ];
        then
                mkdir -p $DIR/$db
        fi
        DUMP="$DIR/$db/$db.xz"
        if [ -f $DUMP ];
        then
                mv $DUMP $DUMP.old
        fi
        mysqldump -h$SERVER -u$USER -p$PASS --single-transaction $db | nice xz -c > $DUMP
        if [ $? != 0 ];
        then
                echo "ERROR: mysqldump of '$db' to file '$DUMP' failed"
        else
                if [ $db = "mysql" ];
                then
                        chmod 600 $DUMP
                fi
		/www/backups/scripts-sync/gfs-rotate -m 3 -w 5 -d 7 $DUMP
		s3cmd sync --delete-removed $DIR/ s3://$BUCKET/dbdumps/
        fi

done

