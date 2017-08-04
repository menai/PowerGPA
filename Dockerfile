FROM ruby:2.3.4

RUN gem install bundler

WORKDIR /app

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock

RUN bundle install --deployment --without development

ADD . /app

EXPOSE 9292

CMD ["bundle", "exec", "foreman", "start", "-f", "Procfile.docker"]
