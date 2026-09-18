# himanshu.co — portfolio + project sites, built with [kite](https://github.com/HimanshuSardana/kite)

My own Go static site generator. Projects curated from https://github.com/HimanshuSardana.

## Layout

| Site | Host | Path | Theme |
| --- | --- | --- | --- |
| Portfolio / blog | `himanshu.co` | repo root | `themes/portfolio/` |
| kite showcase + docs | `kite.himanshu.co` | `kite/` | `kite/themes/showcase/` |
| apollo showcase + docs | `apollo.himanshu.co` | `apollo/` | `apollo/themes/showcase/` |

Each site is a self-contained kite project: its own `config.yaml`, `content/`,
`themes/` and generated `output/` (gitignored, built by CI).

- `config.yaml` — site title, author, theme, canonical `siteUrl`
- `content/*.md` — posts/doc pages (frontmatter: `title`, `date: YYYY-MM-DD`, `tags`)
- `themes/<name>/home.html` — landing page, `layout.html` — content pages

## Dev

```bash
go install github.com/HimanshuSardana/kite@latest

kite serve            # portfolio  -> http://localhost:8000
cd kite   && kite serve --port 8001   # kite showcase
cd apollo && kite serve --port 8002   # apollo showcase
```

## Self-hosting on an Arch Linux VPS (Caddy)

A push to `main` builds all three sites with kite and rsyncs each one to its
web root through GitHub Actions (a matrix job, so one site failing doesn't
block the others). Caddy serves the files and provisions Let's Encrypt certs
automatically for every host.

### 1. One-time server setup (on the VPS, as root)

```bash
git clone https://github.com/HimanshuSardana/portfolio /tmp/portfolio
DOMAIN=himanshu.co bash /tmp/portfolio/deploy/setup-arch.sh
```

This installs Caddy + rsync, creates all three web roots, installs the
Caddyfile from `deploy/Caddyfile`, and enables Caddy.

### 2. DNS

Point these at the VPS IP (A + AAAA): `himanshu.co`, `www.himanshu.co`,
`kite.himanshu.co`, `apollo.himanshu.co`. Caddy issues certs on first request.

The showcase sites previously lived at `himanshu.co/kite/` and
`himanshu.co/apollo/`; Caddy now 301-redirects those subpaths (deep links
included) to the subdomains.

### 3. GitHub Actions secrets (repo → Settings → Secrets → Actions)

| Secret         | Value                                              |
| -------------- | -------------------------------------------------- |
| `VPS_HOST`     | VPS IP or hostname                                 |
| `VPS_PORT`     | SSH port (usually `22`)                            |
| `VPS_USER`     | SSH user that can write `/srv/www/*`               |
| `VPS_SSH_KEY`  | Private ed25519 key (see below)                    |

Generate a deploy key (on your machine):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/portfolio-deploy -N "" -C "portfolio-deploy"
ssh-copy-id -i ~/.ssh/portfolio-deploy.pub -p 22 user@your-vps
```

- Paste the **private** key (`~/.ssh/portfolio-deploy`) into `VPS_SSH_KEY`.
- Make sure `VPS_USER` can write all three web roots:

```bash
# on the VPS, if deploying as a non-caddy user:
chown -R deploy:caddy /srv/www && chmod -R 775 /srv/www
```

After that, `git push origin main` deploys every site. You can also trigger it
manually from the Actions tab (workflow_dispatch).

Builds use a pinned kite revision (`KITE_VERSION` in the workflow) so the
deployed output only changes when the content does. Bump it to pick up new kite
features.

### Manual deploy (no CI)

```bash
KITE=$(go env GOPATH)/bin/kite
$KITE build                && rsync -avz --delete output/       user@vps:/srv/www/portfolio/
(cd kite   && $KITE build) && rsync -avz --delete kite/output/   user@vps:/srv/www/kite/
(cd apollo && $KITE build) && rsync -avz --delete apollo/output/ user@vps:/srv/www/apollo/
```

Check Caddy is happy: `systemctl status caddy`, `journalctl -u caddy -e`,
logs at `/var/log/caddy/{portfolio,kite,apollo}.log`.
