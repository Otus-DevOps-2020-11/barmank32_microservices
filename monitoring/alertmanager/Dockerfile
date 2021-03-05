FROM prom/alertmanager:v0.14.0
ADD config.yml /etc/alertmanager/
ADD docker-entrypoint.sh /etc/alertmanager/
RUN chmod +x /etc/alertmanager/docker-entrypoint.sh
ENTRYPOINT ["/etc/alertmanager/docker-entrypoint.sh"]
