# syntax=docker/dockerfile:1

# ---- Frontend build stage --------------------------------------------------
# Builds the React app with webpack. Output lands in app/assets, where Rails
# (via Propshaft) picks it up and serves it under the 'application' logical
# name referenced by the layout's stylesheet/javascript tags.
FROM node:14-bullseye AS frontend

WORKDIR /app

COPY package.json yarn.lock ./
# --ignore-engines: package.json pins an exact old node patch version that
# isn't worth chasing inside the image.
RUN yarn install --frozen-lockfile --ignore-engines

COPY config ./config
COPY public ./public
COPY scripts ./scripts
COPY src ./src

RUN yarn --ignore-engines build

# ---- Rails app --------------------------------------------------------------
FROM ruby:3.2.4-slim AS app

WORKDIR /app

# build-essential is needed to compile gems without prebuilt binaries (e.g. bcrypt).
# libpq-dev is needed for the pg gem.
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .
# Overwrite whatever build artifacts happen to be committed with a fresh build.
COPY --from=frontend /app/app/assets ./app/assets

RUN chmod +x bin/docker-entrypoint

# Run in development mode: it's already configured for local use (api.localhost
# subdomain support, no forced SSL, secrets committed) and matches how the app
# is meant to be explored/tested locally, as opposed to config/environments/production.rb
# which assumes a real TLS-terminating host (e.g. Render).
ENV RAILS_ENV=development \
    PORT=3001

EXPOSE 3001

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
