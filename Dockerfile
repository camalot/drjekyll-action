# Need a base image with Jekyll and Ruby installed
# The official Jekyll image is a good choice as it comes pre-configured with everything needed to build and serve Jekyll sites.

FROM ruby:3-slim-trixie

ARG USERNAME=drjekyll

# create non-root user and group to run the application
RUN groupadd -r $USERNAME && useradd -r -g $USERNAME $USERNAME

# Native gems (e.g., bigdecimal) require a compiler toolchain on slim images.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends build-essential \
	&& rm -rf /var/lib/apt/lists/*

# Install Jekyll and Bundler
RUN gem install bundler

# copy the jekyll base files to the container
WORKDIR /app

COPY --chown=$USERNAME:$USERNAME docs/. /app/docs/
COPY --chown=$USERNAME:$USERNAME entrypoint.sh /entrypoint.sh

# Install dependencies
RUN bundle config set path /app/docs/vendor/bundle && bundle install --gemfile=/app/docs/Gemfile

# Change ownership of the app directory to the non-root user
RUN chown -R $USERNAME:$USERNAME /app && chmod +x /entrypoint.sh

CMD [ "/entrypoint.sh" ]