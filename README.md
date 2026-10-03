# himanshu.co — portfolio + blog

My portfolio and blog, built with [kite](https://github.com/HimanshuSardana/kite),
my own Go static site generator. Selected work is curated from
[github.com/HimanshuSardana](https://github.com/HimanshuSardana).

## Local development

```sh
go install github.com/HimanshuSardana/kite@latest   # or use a global `kite`

kite serve          # http://localhost:8000 with live reload
kite build          # render into output/
```

## Layout

```
config.yaml                  site title, author, theme
content/*.md                 one file per blog post
themes/portfolio/            the theme (home.html + layout.html)
output/                      build output (gitignored)
.github/workflows/deploy.yml build and rsync to the server
```

## Writing a post

```sh
kite new my-post.md
```

Posts are plain Markdown with frontmatter (`title`, `date`, `tags`).

## Design

The theme follows kite's `minimal-notes` aesthetic: a sans/var palette with a
greyscale accent, a dateline + underlined-title list for writing, the same row
rhythm for selected work, a fixed sidebar table of contents on wide screens and
a light/dark toggle. Home and post pages share the same variables and type
scale, and tag pages reuse the post layout.

## Deployment

Pushing to `main` runs `.github/workflows/deploy.yml`, which installs kite,
builds the site and rsyncs `output/` to the server. It needs these repository
secrets:

| Secret | Meaning |
|---|---|
| `SSH_HOST` | server hostname or IP |
| `SSH_USER` | ssh user |
| `SSH_PORT` | ssh port (falls back to 22) |
| `SSH_DEPLOY_KEY` | private key for that user |
| `DEPLOY_PATH` | absolute directory to rsync into (Caddy's `root`) |

For this site: `SSH_HOST=himanshu.co`, `SSH_USER=himanshu`, `SSH_PORT=22`,
`DEPLOY_PATH=/srv/www/portfolio`.

Caddy on the server serves `/srv/www/portfolio`:

```caddyfile
himanshu.co, www.himanshu.co {
	root * /srv/www/portfolio
	file_server
	encode gzip

	header /*.css Cache-Control "public, max-age=31536000, immutable"
	header /*.html Cache-Control "no-store"
}
```
