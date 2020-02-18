#!/bin/bash

# These URLs should be the only thing to change when upgrading to a new Monit release
MONIT64='https://mmonit.com/monit/dist/binary/5.17.1/monit-5.17.1-linux-x64.tar.gz'
MONIT32='https://mmonit.com/monit/dist/binary/5.17.1/monit-5.17.1-linux-x86.tar.gz'

EXELOCATION="{{ monit_prefix }}/sbin/monit"
CONFLOCATION="{{ monit_prefix }}/etc/monitrc"

source /etc/profile
ARCH=$(uname -m)
TEMPDIR=$(mktemp -d)
OUTFILE=$TEMPDIR/monit.tar.gz

if [ x$ARCH = x"x86_64" ]; then
  MONIT=$MONIT64
else
  MONIT=$MONIT32
fi

wget $MONIT -O $OUTFILE
cd $TEMPDIR
tar xf $OUTFILE
EXTRACTED=$(find -maxdepth 1 -type d -name "monit*")
cp -a $EXTRACTED/bin/monit $EXELOCATION

# Change files' locations in service script
sed -i -r "s#^BIN=.+#BIN=\"$EXELOCATION\"#" /etc/init.d/monit
sed -i -r "s#^CONFIG=.+#CONFIG=\"$CONFLOCATION\"#" /etc/init.d/monit

# Create a symbolic link to make the binary available with a minimal environment
ln -sfn {{ monit_prefix }}/sbin/monit /usr/sbin/monit
