FROM ruby:2.7.2

WORKDIR /app
COPY ./tweleter.rb /app/tweleter.rb
COPY ./Gemfile /app
COPY ./Gemfile.lock /app

COPY ./tweleter /app/tweleter

RUN bundle install

CMD exec /app/tweleter