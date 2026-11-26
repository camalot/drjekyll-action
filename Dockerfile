# Need a base image with Jekyll and Ruby installed
# The official Jekyll image is a good choice as it comes pre-configured with everything needed to build and serve Jekyll sites.

FROM ruby:3-slim-trixie

ARG TARGETARCH=amd64
ARG YQ_VERSION=4.44.3

# Native gems (e.g., bigdecimal) require a compiler toolchain on slim images.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends curl build-essential rsync openssl libssl-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl --fail --location --retry 3 \
		"https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" \
		--output /tmp/yq \
	&& chmod +x /tmp/yq \
	&& /tmp/yq --version \
	&& mv /tmp/yq /usr/local/bin/yq

# Install Jekyll and Bundler
RUN gem install bundler

# copy the jekyll base files to the container
WORKDIR /app

COPY drjekyll/. /app/docs/
COPY entrypoint.sh /entrypoint.sh

# Install dependencies
RUN bundle config set path /app/docs/vendor/bundle && bundle install --gemfile=/app/docs/Gemfile

RUN chmod +x /entrypoint.sh

CMD [ "/entrypoint.sh" ]
