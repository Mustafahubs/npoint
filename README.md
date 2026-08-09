# n:point

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Live Demo](https://img.shields.io/badge/demo-npoint.fastapi.us-6BA539?logo=googlechrome&logoColor=white)](https://npoint.fastapi.us/)
[![Docker](https://img.shields.io/badge/docker-ready-2496ED?logo=docker&logoColor=white)](#run-it-locally-with-docker)
[![Rails](https://img.shields.io/badge/rails-8.1-CC0000?logo=rubyonrails&logoColor=white)](Gemfile)
[![Ruby](https://img.shields.io/badge/ruby-3.2.4-CC342D?logo=ruby&logoColor=white)](Gemfile)
[![OpenAPI](https://img.shields.io/badge/API-OpenAPI%203.0-6BA539?logo=openapiinitiative&logoColor=white)](openapi.yaml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

n:point is a lightweight JSON data store for your app or prototype.
Originally created by [Alex Zirbel](https://github.com/azirbel) as
[npoint.io](https://www.npoint.io/); this is a self-hosted, open-source fork
maintained by [Mustafahubs](https://github.com/Mustafahubs) — see
[Copyright & License](#copyright--license) for full attribution.

🚀 **[Try the live demo of this fork](https://npoint.fastapi.us/)** — the
public API is served from
[api-npoint.fastapi.us](https://api-npoint.fastapi.us/) (see
[why it's `api-npoint.` and not `api.npoint.`](docs/cloudflare-tunnel.md)).

Save FAQ answers, customer stories, configuration data, or anything else that
will fit in a JSON blob. Then access your data directly via API.

Once your app is live, come back later to edit your saved JSON without having
to redeploy. Or share a login with a friend so they can help you experiment!
Features like schema validation and locking mean you can make these changes
confidently, without breaking your app.

![Demo screenshot](public/img/demo-screenshot-locked.png)

## Table of contents

- [Run it locally with Docker](#run-it-locally-with-docker)
- [Expose it over the internet](#expose-it-over-the-internet)
- [API documentation](#api-documentation)
- [Contributing](#contributing)
- [Development](#development)
- [Maintaining](#maintaining)
- [Self-hosting elsewhere](#self-hosting-elsewhere)
- [Similar tools](#similar-tools)
- [Copyright & license](#copyright--license)

## Run it locally with Docker

🐳 The fastest way to get n:point running on your own machine — no Ruby,
Node, Postgres, or Redis installation required.

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose).
2. Clone the repo and start it up:

   ```bash
   git clone https://github.com/Mustafahubs/npoint.git
   cd npoint
   docker compose up --build
   ```

3. Open [http://localhost:3001](http://localhost:3001).

The first run builds the frontend, installs gems, and sets up the database
for you. Your data persists in a Docker volume between runs; use
`docker compose down -v` if you want to wipe it and start fresh.

If port `3001` is already in use on your machine, change the host side of
the port mapping in `docker-compose.yml` (e.g. `"8080:3001"`) and also
uncomment/set `PUBLIC_PORT` in the `web` service's environment to match —
otherwise links the app generates (like a document's public API URL) will
point at the wrong port. See the comments in `docker-compose.yml`.

## Expose it over the internet

🌐 Already have a domain on Cloudflare? You can make your local Docker
deployment reachable from the internet on a subdomain — no port-forwarding,
static IP, or extra server required — using a
[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

See **[docs/cloudflare-tunnel.md](docs/cloudflare-tunnel.md)** for the full,
step-by-step guide, including the Cloudflare dashboard setup and the
`docker-compose.tunnel.yml` overlay that runs alongside your existing local
setup.

## API documentation

📖 n:point's HTTP API (account management, document CRUD, schema
validation, and the public `api.<host>` document-access API) is fully
documented as an [OpenAPI 3.0](https://www.openapis.org/) spec.

Once your instance is running (locally or over a tunnel), open
**`/api-docs`** in a browser for interactive, browsable documentation
(rendered with [Redoc](https://github.com/Redocly/redoc)) — for example
[http://localhost:3001/api-docs](http://localhost:3001/api-docs) for a local
Docker setup. The raw spec is served alongside it at `/openapi.yaml`
(source: [`openapi.yaml`](openapi.yaml)), so you can also load it into tools
like [Swagger UI](https://swagger.io/tools/swagger-ui/),
[Postman](https://www.postman.com/), or generate an API client with
[OpenAPI Generator](https://openapi-generator.tech/).

## Contributing

Contributions are welcome!

Please open an issue to discuss proposed changes, rather than opening a pull
request directly.

## Development

If you want to run the app natively (not in Docker) to work on it — for
just using n:point, the [Docker setup](#run-it-locally-with-docker) above is
much simpler and is what most people should use.

#### Setup

It's an old project. To get things running nicely:

```
# Something like this
asdf use nodejs v25.2.1

# Might need this?
# Python 3.11 introduced an issue that node-gyp hits when building. Use older version
brew install python@3.10
export NODE_GYP_FORCE_PYTHON=/opt/homebrew/bin/python3.10
```

```bash
bundle
```

Note that I'm not using yarn now for local builds; can't seem to get it to reliably install.

Yarn is still used in deploys.

#### Running locally

```bash
rails s -p 3001
node scripts/start.js
```

#### Testing

Setup:

1. Install Chrome
2. Install chromedriver (`brew install chromedriver` on mac)

```bash
rspec
node jest  # no jest tests yet
```

**Important note**: Rspec integration tests run against the compiled version of the
app in `app/assets`. Build with `node scripts/build.js` first, or set up capybara to run against
your live webpack version (I haven't done this yet, but have ideas in `spec_helper.rb`).

## Maintaining

#### Production build

```bash
# 1. Build files
node scripts/build.js

# 2. Make an "Add build files" commit
git commit -a -m "Add build files"
```

#### Deploying

Push to main. This deploys staging.

Deploy prod manually via render UI.

#### Bandwidth tracking (Admin)

To monitor which API documents are using the most bandwidth, first set credentials:

```bash
export ADMIN_USERNAME=your_username
export ADMIN_PASSWORD=your_secure_password
```

Then access the endpoint with HTTP Basic Auth:

```bash
# View top 20 documents by bandwidth (last 24 hours)
curl -u $ADMIN_USERNAME:$ADMIN_PASSWORD http://localhost:3001/admin/bandwidth

# Custom time window and limit
curl -u $ADMIN_USERNAME:$ADMIN_PASSWORD http://localhost:3001/admin/bandwidth?hours=12&limit=50

# Clear tracking data
curl -u $ADMIN_USERNAME:$ADMIN_PASSWORD -X POST http://localhost:3001/admin/bandwidth/clear
```

Tracking runs in-memory and automatically cleans up data older than 24 hours.
This endpoint is disabled (returns `503`) unless both env vars above are set.

## Similar tools

* [JSONbin.io](https://jsonbin.io/)
* [Firebase](https://firebase.google.com/)
* [AirTable](https://airtable.com)
* [JSON Schema Validator](https://www.jsonschemavalidator.net/)

## Bookmarks

* [JSON Schema](http://json-schema.org/)
* [JSON in Postgres](https://blog.codeship.com/unleash-the-power-of-storing-json-in-postgres/)

## Self-hosting elsewhere

Want to run your own instance of n:point somewhere other than Docker? Go
right ahead — there are a few paths depending on what you're optimizing for:

- **Local use, or exposed via a tunnel**: see
  [Run it locally with Docker](#run-it-locally-with-docker) and
  [Expose it over the internet](#expose-it-over-the-internet) above.
  `Dockerfile` and `docker-compose.yml` are also a good starting point for
  deploying to any other container host (Fly.io, Railway, a VPS with Docker,
  etc).
- **A traditional PaaS deployment**: [render.com](https://render.com/) is
  what the original project uses for [npoint.io](https://www.npoint.io).

  1. Set up a hosted Postgres DB in Render, and make sure `DATABASE_URL` points there.
  2. Set up a hosted Redis (or [Valkey](https://valkey.io/)) instance, and make sure `REDIS_URL` points there — required for rate limiting (Rack::Attack).
  3. Configure environment variables. You'll at least need:
     - `HOST` (e.g. `yourdomain.com`)
     - `SECRET_KEY_BASE` (generate with `bin/rails secret`)
     - `RAILS_MAX_THREADS`, `RAILS_SERVE_STATIC_FILES=true` (typical Rails production settings)
     - `CLOUDFLARE_API_TOKEN` (optional, for cache purging — a different feature from the [Cloudflare Tunnel](docs/cloudflare-tunnel.md) setup above)
     - `CLOUDFLARE_ZONE_ID` (optional, for cache purging)
  4. Use these Render settings:

     ```
     # build command
     ./build.sh

     # start command
     ./start.sh
     ```

  Password-reset emails go through a [SendGrid](https://sendgrid.com/)
  account (`SENDGRID_API_KEY`) using a dynamic email template ID that lives
  in the original maintainer's SendGrid account — you'll need to create your
  own template and swap in its ID (see the comment in
  `app/lib/transactional_mail.rb`), or remove the feature and handle
  password resets yourself.

## Codebase TODOs / Wishlist

* Add a real error-tracking service — this fork removed `sentry-raven`
  (search history for why: it was unconfigured, deprecated, and was
  actually swallowing/misrouting unhandled exceptions app-wide). Nothing
  has replaced it yet.
* This fork's Docker image no longer ships Google Analytics or the Crisp
  chat widget (they pointed at the original maintainer's accounts); a
  privacy-respecting, self-hostable replacement (e.g.
  [Plausible](https://plausible.io/) or [Umami](https://umami.is/)) hasn't
  been added.
* More testing (search: `TODO(test)`)

## Copyright & license

Copyright (c) 2017-2018 Alexander Zirbel, copyright (c) 2026 Mustafahubs
(this fork) - Code released under the [MIT license](LICENSE).
