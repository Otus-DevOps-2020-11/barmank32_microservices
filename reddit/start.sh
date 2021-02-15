#!/bin/sh
[ "$(stat -c %U /data/db)" = mongodb ] || chown -R mongodb /data/db
/usr/bin/mongod --fork --syslog

cd /reddit && puma || exit
