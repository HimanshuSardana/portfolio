# ---- Arch Linux VPS setup for himanshu.co (Astro static site, Caddy) ----
# Run ONCE on the VPS as root (or with sudo):
#   git clone https://github.com/HimanshuSardana/portfolio /tmp/portfolio
#   DOMAIN=himanshu.co bash /tmp/portfolio/deploy/setup-arch.sh
#
# What it does:
#   1. Installs caddy + rsync
#   2. Creates /srv/www/portfolio (the deploy target)
#   3. Installs the Caddyfile for himanshu.co (automatic HTTPS)
#   4. Enables + starts caddy
#
# Deploy afterwards by pushing to main (GitHub Action rsyncs dist/).

set -euo pipefail

DOMAIN="${DOMAIN:-himanshu.co}"
WEBROOT="/srv/www/portfolio"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

echo "==> Installing caddy + rsync"
pacman -Syu --noconfirm --needed caddy rsync

echo "==> Creating web root $WEBROOT"
mkdir -p "$WEBROOT"
chown -R caddy:caddy /srv/www
chmod -R 755 /srv/www
# Placeholder page until the first deploy lands
[[ -f "$WEBROOT/index.html" ]] || echo "<h1>Deploy pending — push to main.</h1>" > "$WEBROOT/index.html"

echo "==> Installing Caddyfile for $DOMAIN"
if [[ -f /etc/caddy/Caddyfile ]]; then
  cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)"
  echo "    (backed up existing Caddyfile)"
fi
sed "s/__DOMAIN__/$DOMAIN/g" "$SCRIPT_DIR/Caddyfile" > /etc/caddy/Caddyfile

echo "==> Validating + starting caddy"
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
systemctl enable --now caddy

echo "==> Opening HTTP/HTTPS in firewall (if firewalld is active)"
if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-service={http,https}
  firewall-cmd --reload
else
  echo "    firewalld not active, skipping."
fi

echo
echo "Done. Next steps:"
echo "  1. Point DNS A/AAAA records for $DOMAIN (and www) at this VPS."
echo "     Caddy will issue Let's Encrypt certs automatically on first request."
echo "  2. Add GitHub Actions secrets (see README) and push to main to deploy."
echo "  3. If deploying as a non-caddy user, allow writes to the web root:"
echo "       chown -R deploy:caddy /srv/www/portfolio && chmod -R 775 /srv/www/portfolio"
