# ---- Arch Linux VPS setup for himanshu.co + project subsites (Caddy) ----
# Run ONCE on the VPS as root (or with sudo):
#   git clone https://github.com/HimanshuSardana/portfolio /tmp/portfolio
#   DOMAIN=himanshu.co bash /tmp/portfolio/deploy/setup-arch.sh
#
# What it does:
#   1. Installs caddy + rsync
#   2. Creates the three deploy targets:
#        /srv/www/portfolio  -> himanshu.co
#        /srv/www/kite       -> kite.himanshu.co
#        /srv/www/apollo     -> apollo.himanshu.co
#   3. Installs the Caddyfile (automatic HTTPS for all three hosts)
#   4. Enables + starts caddy
#
# Deploy afterwards by pushing to main (GitHub Action rsyncs each site).

set -euo pipefail

DOMAIN="${DOMAIN:-himanshu.co}"
ROOTS=(/srv/www/portfolio /srv/www/kite /srv/www/apollo)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

echo "==> Installing caddy + rsync"
pacman -Syu --noconfirm --needed caddy rsync

echo "==> Creating web roots"
mkdir -p "${ROOTS[@]}"
chown -R caddy:caddy /srv/www
chmod -R 755 /srv/www
# Placeholder page until the first deploy lands
for root in "${ROOTS[@]}"; do
  [[ -f "$root/index.html" ]] || echo "<h1>Deploy pending — push to main.</h1>" > "$root/index.html"
done

echo "==> Installing Caddyfile (himanshu.co, kite.$DOMAIN, apollo.$DOMAIN)"
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
echo "  1. DNS: point A/AAAA records for $DOMAIN, www.$DOMAIN,"
echo "     kite.$DOMAIN and apollo.$DOMAIN at this VPS."
echo "     Caddy issues certs automatically on first request."
echo "  2. Add GitHub Actions secrets (see README) and push to main to deploy."
echo "  3. If deploying as a non-caddy user, allow writes to the web roots:"
echo "       chown -R deploy:caddy /srv/www && chmod -R 775 /srv/www"
