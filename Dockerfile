FROM alpine:3.9

RUN apk update \
    && apk add --no-cache mongodb ruby-full ruby-dev build-base \
    && gem install bundler:1.17.2

VOLUME /data/db
ENV APP_HOME /reddit
WORKDIR $APP_HOME
COPY reddit/ $APP_HOME

RUN bundle install && \
    chmod 0777 start.sh

CMD ["./start.sh"]
