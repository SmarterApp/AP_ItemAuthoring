#!/bin/bash
INSTANCE=cdesbac
CDEHOME=/home/pacific
PIDFILE=$CDEHOME/$INSTANCE.pid
STATUSFILE=$CDEHOME/$INSTANCE.status

if [ -a $PIDFILE ]; then
  cd /www/$INSTANCE/cgi-bin && /usr/bin/start_server --restart --pid-file=$PIDFILE --status-file=$STATUSFILE
else
  cd /www/$INSTANCE/cgi-bin && /usr/bin/start_server --port=5000 --pid-file=$PIDFILE --status-file=$STATUSFILE -- /usr/local/bin/plackup -E $INSTANCE --server Starlet --host localhost --max-workers=30 --app /www/$INSTANCE/cgi-bin/cde.psgi --access-log $CDEHOME/$INSTANCE-access.txt 2> $CDEHOME/$INSTANCE-error.txt
fi
