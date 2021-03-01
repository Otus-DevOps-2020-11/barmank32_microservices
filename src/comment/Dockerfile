FROM alpine:latest

RUN apk update \
    && apk add --no-cache ruby-full ruby-dev build-base \
    && gem install bundler:1.17.2

ENV APP_HOME /app
ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

WORKDIR $APP_HOME
COPY . $APP_HOME

RUN bundle install
EXPOSE 9292
CMD ["puma"]
