# Need a base image with Jekyll and Ruby installed
# The official Jekyll image is a good choice as it comes pre-configured with everything needed to build and serve Jekyll sites.

FROM ruby:3-slim-trixie

ARG USERNAME=drjekyll

# create non-root user and group to run the application
RUN groupadd -r $USERNAME && useradd -r -g $USERNAME $USERNAME

# Install Jekyll and Bundler
RUN gem install bundler

# copy the jekyll base files to the container
WORKDIR /app

COPY --chown=$USERNAME:$USERNAME docs/** /app/
COPY --chown=$USERNAME:$USERNAME entrypoint.sh /entrypoint.sh

# Install dependencies
RUN bundle install

# Change ownership of the app directory to the non-root user
RUN chown -R $USERNAME:$USERNAME /app