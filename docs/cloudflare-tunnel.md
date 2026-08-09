# Exposing your local n:point over the internet with a Cloudflare Tunnel

This guide is for anyone who already has a domain added to Cloudflare and
wants to make their local Docker deployment (see the main
[README](../README.md#run-it-locally-with-docker)) reachable from the
internet on a subdomain, **without** port-forwarding, a public IP, or a
separate server. [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
runs a small process (`cloudflared`) next to your app that makes an
outbound-only connection to Cloudflare's network; Cloudflare then routes
requests for your chosen subdomain to it.

You do not need to run `cloudflared` separately - it runs as an extra
container alongside the app, defined in `docker-compose.tunnel.yml`.

## What you'll end up with

- Your local Docker deployment, reachable at a subdomain you choose, e.g.
  `https://npoint.yourdomain.com` - automatically TLS-terminated by
  Cloudflare, no certificate setup needed.
- The public JSON API also reachable at a second hostname (n:point routes
  its public document-access API from a distinct host - see the
  [OpenAPI docs](/api-docs) once the app is running). Both routes point at
  the exact same container; Rails tells them apart by the `Host` header,
  same as it does locally with `api.localhost`.

**Important - Cloudflare's free plan only certifies one level of
subdomain.** Its Universal SSL certificate covers `yourdomain.com` and
`*.yourdomain.com`, but *not* a second level like
`api.npoint.yourdomain.com` - that request would fail TLS entirely. So the
exact hostname to use for the API depends on which pattern you pick below;
either way, keep both hostnames exactly **one label** under your apex
domain.

| Pattern | Main app | Public API |
|---|---|---|
| Dedicated subdomain (recommended if you use this domain for other things) | `npoint.yourdomain.com` | `api-npoint.yourdomain.com` (hyphen, not a dot - see why above) |
| Bare apex domain | `yourdomain.com` | `api.yourdomain.com` |

Both are one label under `yourdomain.com`, so both work fine on Cloudflare's
free plan. This guide uses the dedicated-subdomain pattern; substitute the
apex-domain values if you'd rather use that instead (and skip setting
`API_SUBDOMAIN` in step 3 - `api` is the default).

## 1. Create a tunnel

1. Open the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/)
   for the account your domain is on.
2. Go to **Networks → Tunnels → Create a tunnel**.
3. Choose **Cloudflared**, give it a name (e.g. `npoint`), and continue.
4. On the "Install and run a connector" step, pick the **Docker** tab.
   Cloudflare shows you a `docker run` command containing a long `--token`
   value - copy just that token, you won't use the rest of the command
   (docker-compose.tunnel.yml already runs `cloudflared` for you).
5. Keep this browser tab open; the next step is on the same page.

## 2. Route a public hostname to your container

Still on the tunnel's configuration page, go to **Public Hostname → Add a
public hostname**, and add two entries, both pointing at the same service:

| Field       | First entry                     | Second entry                        |
|-------------|----------------------------------|--------------------------------------|
| Subdomain   | `npoint` (or whatever you like)  | `api-npoint` (hyphen, matching the first - see why above) |
| Domain      | `yourdomain.com`                 | `yourdomain.com`                     |
| Path        | *(leave blank)*                  | *(leave blank)*                      |
| Type        | HTTP                             | HTTP                                 |
| URL         | `web:3001`                       | `web:3001`                           |

`web` is the Docker Compose service name for the app - Cloudflare's
connector resolves it over the Docker network, so there's no need to expose
a port to your host machine for this to work. (`docker-compose.yml` still
publishes port 3001 to your host by default too, so local access keeps
working side by side.)

If you'd rather dedicate your whole domain to n:point instead of a
subdomain, use `yourdomain.com` and `api.yourdomain.com` instead (a plain
dot works here since it's still only one label deep) - see step 3.

## 3. Configure environment variables

Create a `.env` file in the repo root (same folder as `docker-compose.yml`):

```bash
# .env
CLOUDFLARE_TUNNEL_TOKEN=paste-the-token-from-step-1-here
HOST=npoint.yourdomain.com

# Only needed for the dedicated-subdomain pattern (as set up above) - tells
# the app to route/generate API links at api-npoint.<HOST's domain> instead
# of the default api.<HOST>, since api.npoint.yourdomain.com wouldn't get a
# certificate on Cloudflare's free plan (see the note above step 1).
# Match whatever subdomain you actually used in step 2. Not needed at all
# if you're using the bare-apex-domain pattern instead - leave it unset and
# "api" (the default) is correct.
API_SUBDOMAIN=api-npoint

# Generate a real secret - do NOT skip this, the default committed secret
# is public (it's in this open-source repo) and must not be used for
# anything reachable from the internet.
# Run: docker compose run --rm web bin/rails secret
SECRET_KEY_BASE=paste-the-generated-secret-here
```

**About `TLD_LENGTH`**: not needed for either pattern above with a standard
`yourdomain.com`-style domain - Rails' own default is already correct,
since both the main app and API hosts are exactly one label under a
2-label domain either way. Only set it if your domain has a multi-part
suffix (e.g. `yourdomain.co.uk` needs `TLD_LENGTH=2`).

Getting `API_SUBDOMAIN` wrong (or Cloudflare's Public Hostname routes not
matching it) doesn't break the main site, only the API host (document
GET/POST-by-token, and the API links n:point generates in its UI) - if
those stop working after you deploy, double check this value first.

## 4. Start it

```bash
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d --build
```

Give it a minute for the tunnel to connect, then visit
`https://npoint.yourdomain.com` (using whatever subdomain you chose).

Check the tunnel's own logs if it doesn't come up:

```bash
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml logs cloudflared
```

## Optional: password-reset emails and admin bandwidth tracking

These aren't required for the tunnel to work, but matter more once the app
is actually reachable by other people:

- Password-reset emails need a [SendGrid](https://sendgrid.com/) account -
  set `SENDGRID_API_KEY` in `.env` (see the main README's Self-hosting
  section for the caveat about the dynamic email template).
- The `/admin/bandwidth` endpoint is disabled unless you set
  `ADMIN_USERNAME`/`ADMIN_PASSWORD` in `.env` - worth doing once this is
  public, so you can see who's using your API and how much.

## Tearing it down

```bash
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml down
```

Then delete the tunnel from the Cloudflare Zero Trust dashboard if you don't
plan to reuse it.

## Reference links

- [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/)
- [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [cloudflared on GitHub](https://github.com/cloudflare/cloudflared)
- [cloudflared Docker image](https://hub.docker.com/r/cloudflare/cloudflared)
