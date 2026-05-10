# Need a base image with Jekyll and Ruby installed
# The official Jekyll image is a good choice as it comes pre-configured with everything needed to build and serve Jekyll sites.

FROM ruby:3-slim-trixie

ARG USERNAME=drjekyll

# create non-root user and group to run the application with a home directory
RUN groupadd -r $USERNAME && useradd -r -g $USERNAME -d /home/$USERNAME -m $USERNAME

# Native gems (e.g., bigdecimal) require a compiler toolchain on slim images.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends curl jq build-essential rsync \
	&& rm -rf /var/lib/apt/lists/* \
  && YQ_VERSION=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r ".tag_name" | sed 's/v//') \
  && curl -X GET -Ls "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o /usr/bin/yq \
  && chmod +x /usr/bin/yq

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

USER $USERNAME

CMD [ "/entrypoint.sh" ]