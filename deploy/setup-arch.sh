# ---- Arch Linux VPS setup: himanshu.co + kite/apollo subsites (Caddy) ----
# Run on the VPS as root (or with sudo). Safe to re-run: it backs up the
# current Caddyfile, preserves your live sites (search/demo/ai/neuroshield),
# and only restarts caddy after the new config validates.
#
#   git clone https://github.com/HimanshuSardana/portfolio /tmp/portfolio
#   DOMAIN=himanshu.co bash /tmp/portfolio/deploy/setup-arch.sh
#
# The repo Caddyfile contains a __SEARXNG_KEY__ placeholder (the real key must
# never be committed). It is filled in automatically from the live Caddy state
# (/var/lib/caddy/autosave.json). Override with:
#   SEARXNG_KEY=<64-hex> bash deploy/setup-arch.sh

set -euo pipefail

DOMAIN="${DOMAIN:-himanshu.co}"
DEPLOY_USER="${DEPLOY_USER:-himanshu}"
SEARXNG_KEY="${SEARXNG_KEY:-}"
ROOTS=(/srv/www/portfolio /srv/www/kite /srv/www/apollo)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

# The searxng API key lives only on the server, never in git.
if [[ -z "$SEARXNG_KEY" && -f /var/lib/caddy/autosave.json ]]; then
  SEARXNG_KEY=$(grep -oP 'X-Api-Key": \["\K[0-9a-f]{64}' /var/lib/caddy/autosave.json | head -n 1 || true)
fi
if [[ -z "$SEARXNG_KEY" ]]; then
  echo "ERROR: set SEARXNG_KEY=<64-hex> (could not read it from /var/lib/caddy/autosave.json)." >&2
  exit 1
fi

echo "==> Installing caddy + rsync"
pacman -Syu --noconfirm --needed caddy rsync

echo "==> Creating web roots (writable by $DEPLOY_USER)"
mkdir -p "${ROOTS[@]}"
chown -R "$DEPLOY_USER:caddy" /srv/www
chmod -R 775 /srv/www
# Placeholder page until the first deploy lands
for root in "${ROOTS[@]}"; do
  [[ -f "$root/index.html" ]] || echo "<h1>Deploy pending — push to main.</h1>" > "$root/index.html"
done

echo "==> Installing Caddyfile"
if [[ -f /etc/caddy/Caddyfile ]]; then
  cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)"
  echo "    (backed up existing Caddyfile)"
fi
sed -e "s/__DOMAIN__/$DOMAIN/g" -e "s/__SEARXNG_KEY__/$SEARXNG_KEY/g" \
  "$SCRIPT_DIR/Caddyfile" > /etc/caddy/Caddyfile

echo "==> Validating new config"
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

echo "==> Restarting caddy (brief downtime for all sites, ~seconds)"
systemctl enable --now caddy
systemctl restart caddy
systemctl is-active caddy

echo "==> Opening HTTP/HTTPS in firewall (if firewalld is active)"
if systemctl is-active --quiet firewalld; then
  firewall-cmd --permanent --add-service={http,https}
  firewall-cmd --reload
else
  echo "    firewalld not active, skipping."
fi

echo
echo "Done. Next steps:"
echo "  1. DNS: A/AAAA for $DOMAIN, www.$DOMAIN, kite.$DOMAIN, apollo.$DOMAIN"
echo "     must point at this VPS. Caddy issues certs on first request."
echo "  2. Deploy the sites (from your machine): push to main, or rsync manually"
echo "     (see README). Legacy /kite/* and /apollo/* URLs 301 to the subdomains."
