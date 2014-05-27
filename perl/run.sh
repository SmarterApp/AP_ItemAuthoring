#!/bin/bash
INSTANCE=devcdesbac
CDEHOME=/home/pacific
PIDFILE=$HOME/$INSTANCE.pid
STATUSFILE=$HOME/$INSTANCE.status

if [ -a $PIDFILE ]; then
  cd /www/$INSTANCE/cgi-bin && /usr/bin/start_server --restart --pid-file=$PIDFILE --status-file=$STATUSFILE
else
  cd /www/$INSTANCE/cgi-bin && /usr/bin/start_server --port=5000 --pid-file=$PIDFILE --status-file=$STATUSFILE -- plackup -E $INSTANCE --server Starlet --host localhost --max-workers=30 --app /www/$INSTANCE/cgi-bin/cde.psgi --access-log $CDEHOME/$INSTANCE-access.txt 2> $CDEHOME/$INSTANCE-error.txt
fi
