#!/bin/sh
set -e

echo "🔐 Checking SSL certificates..."

reload_nginx() {
    mkdir -p /var/run/certbot
    touch /var/run/certbot/reload-nginx
    echo "🔄 Requested nginx reload"
}

# Get list of domains from nginx config
DOMAINS=$(sed -nr 's/^\s*server_name\s+([^;]+);/\1/p' /etc/nginx/conf.d/*.conf /etc/nginx/nginx.conf 2>/dev/null | tr ' ' '\n' | grep -vE '^(_|\$)' | sort -u)

if [ -z "$DOMAINS" ]; then
    echo "No domains found in nginx config. Skipping certificate renewal."
    exit 0
fi

echo "Found domains: $DOMAINS"

# Request/renew certificates for each domain
for domain in $DOMAINS; do
    domain=$(echo "$domain" | xargs)  # Trim whitespace
    
    if [ -z "$domain" ] || [ "$domain" = "_" ]; then
        continue
    fi
    
    echo "Processing domain: $domain"
    
    # Check if certificate exists
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        echo "✓ Certificate exists for $domain, attempting renewal..."
        if certbot renew --webroot -w /var/www/certbot --cert-name "$domain" --quiet; then
            reload_nginx
        fi
    else
        echo "⚠ No certificate found for $domain, requesting new certificate..."
        certbot certonly \
            --webroot \
            -w /var/www/certbot \
            --email admin@$domain \
            --agree-tos \
            --no-eff-email \
            --force-renewal \
            -d "$domain" || {
                echo "❌ Failed to obtain certificate for $domain"
                echo "Make sure:"
                echo "  1. Domain DNS points to this server"
                echo "  2. Port 80 is accessible"
                echo "  3. Nginx is serving /.well-known/acme-challenge/"
                continue
            }
        
        echo "✅ Certificate obtained for $domain"
        
        # Reload nginx to use the new certificate
        reload_nginx
    fi
done

echo "✅ SSL certificate check complete"
