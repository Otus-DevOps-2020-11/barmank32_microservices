#!/bin/sh -e

cat /etc/alertmanager/config.yml |\
    sed "s@#api_url: <url>#@api_url: '$SLACK_URL'@g" |\
    sed "s@#channel: <channel>#@channel: '#$SLACK_CHANNEL'@g" |\
    sed "s@#username: <user>#@username: '$SLACK_USER'@g" > /tmp/config.yml

mv /tmp/config.yml /etc/alertmanager/config.yml

set -- /bin/alertmanager "$@"

exec "$@"
