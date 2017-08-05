FROM ruby:2.3.4

RUN gem install bundler

WORKDIR /app
ADD . /app

RUN bundle install --deployment --without development

EXPOSE 9292

HEALTHCHECK --interval=10s --timeout=3s CMD curl --fail http://localhost:9292/ping || exit 1

CMD ["bundle", "exec", "foreman", "start", "-f", "Procfile.docker"]
