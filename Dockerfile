FROM azuresdk/azure-cli-python

RUN apk add --update mysql-client && rm -f /var/cache/apk/*

ADD start.sh /etc/periodic/daily/start
RUN chmod 0755 /etc/periodic/daily/start

ENTRYPOINT ["crond", "-f"]