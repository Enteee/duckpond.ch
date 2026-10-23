ARG jekyll_version=4.4.1
FROM jekyll/jekyll:${jekyll_version}

# The 4.x images dropped the entrypoint that used to run `bundle install` at
# container start, and the site is mounted read-only at runtime. So install
# the site's gems at build time instead: reproducible, and no network needed
# when the container starts.
#
# Build context is the repository root (see docker-compose.yml) so that the
# site's Gemfile is visible here.
COPY Gemfile Gemfile.lock /srv/jekyll/
WORKDIR /srv/jekyll
RUN set -ex \
  && bundle install
