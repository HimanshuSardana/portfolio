# himanshu.co — portfolio + blog, built with [kite](https://github.com/HimanshuSardana/kite)

My own Go static site generator. Projects curated from https://github.com/HimanshuSardana.

## Layout

- `config.yaml` — site title, author, theme
- `content/*.md` — blog posts (frontmatter: `title`, `date: YYYY-MM-DD`, `tags`)
- `themes/portfolio/` — custom theme (`home.html` single page + `layout.html` post pages)
- `output/` — generated site (gitignored, built by CI)
- `kite/` — standalone showcase subsite for kite itself (own `config.yaml`,
  `content/`, `themes/`). Built with kite, deployed to `/kite/`:
  `cd kite && kite build` (preview: `kite serve --port 8001`)
- `apollo/` — same treatment for the apollo CLI agent, deployed to `/apollo/`
  (preview: `cd apollo && kite serve --port 8002`)

## Dev

```bash
go install github.com/HimanshuSardana/kite@latest
kite serve            # http://localhost:8000 with live reload
kite build            # -> output/
```

## Self-hosting on an Arch Linux VPS (Caddy)

Every push to `main` builds the site with kite and rsyncs `output/` to `/srv/www/portfolio` on your VPS via GitHub Actions. Caddy serves the files and handles HTTPS (Let's Encrypt) automatically.

### 1. One-time server setup (on the VPS, as root)

```bash
git clone https://github.com/HimanshuSardana/portfolio /tmp/portfolio
DOMAIN=himanshu.co bash /tmp/portfolio/deploy/setup-arch.sh
```

This installs Caddy + rsync, creates `/srv/www/portfolio`, installs the
Caddyfile from `deploy/Caddyfile`, and enables Caddy.

### 2. DNS

Point `himanshu.co` and `www.himanshu.co` (A + AAAA) at the VPS IP.
Caddy issues certs on first request — no certbot needed.

### 3. GitHub Actions secrets (repo → Settings → Secrets → Actions)

| Secret         | Value                                              |
| -------------- | -------------------------------------------------- |
| `VPS_HOST`     | VPS IP or hostname                                 |
| `VPS_PORT`     | SSH port (usually `22`)                            |
| `VPS_USER`     | SSH user that can write `/srv/www/portfolio`       |
| `VPS_SSH_KEY`  | Private ed25519 key (see below)                    |

Generate a deploy key (on your machine):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/portfolio-deploy -N "" -C "portfolio-deploy"
ssh-copy-id -i ~/.ssh/portfolio-deploy.pub -p 22 user@your-vps
```

- Paste the **private** key (`~/.ssh/portfolio-deploy`) into `VPS_SSH_KEY`.
- Make sure `VPS_USER` can write the web root on the VPS:

```bash
# on the VPS, if deploying as a non-caddy user:
chown -R deploy:caddy /srv/www/portfolio && chmod -R 775 /srv/www/portfolio
```

After that, `git push origin main` deploys automatically. You can also
trigger it manually from the Actions tab (workflow_dispatch).

### Manual deploy (no CI)

```bash
kite build
rsync -avz --delete output/ user@your-vps:/srv/www/portfolio/
```

Check Caddy is happy: `systemctl status caddy`, `journalctl -u caddy -e`,
logs at `/var/log/caddy/portfolio.log`.
