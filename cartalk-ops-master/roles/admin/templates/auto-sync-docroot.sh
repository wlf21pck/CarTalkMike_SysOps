#!/bin/sh
#
# auto-sync-docroot.sh
#
# ATonns Thu Jan 25 16:27:24 EST 2007
#

( /bin/echo -n "sync $$ starting: "; date ) >> /var/log/auto-sync-docroot.log
SRCDIR="/www/docs"
DSTDIR="/www/docs"
DSTHOSTS="{{ sync_instances | join(' ') }}"

if [ ! -d $SRCDIR ];
then
        echo "ERROR: docroot directory '$SRCDIR' does not exist"
        exit 1
fi

for HOST in $DSTHOSTS
do
        echo "syncing $SRCDIR/ to $HOST:$DSTDIR/" > /dev/null
        rsync   --quiet \
                --rsh="/usr/bin/ssh -o StrictHostKeyChecking=no -c blowfish-cbc" \
                --archive \
                --whole-file \
                --delete \
                $EXTRA_RSYNCARGS $SRCDIR/ $HOST:$DSTDIR/
done

#
# removed rsync options
#               --checksum \

( /bin/echo -n "sync $$ finished: "; date ) >> /var/log/auto-sync-docroot.log
