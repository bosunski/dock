#!/bin/sh
set -e

echo "🔐 Checking SSL certificates..."

# Get list of domains from nginx config
DOMAINS=$(grep -oP 'server_name \K[^;]+' /etc/nginx/nginx.conf 2>/dev/null | grep -v '_' | sort -u || true)

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
        certbot renew --webroot -w /var/www/certbot --cert-name "$domain" --quiet --deploy-hook "nginx -s reload" || true
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
        docker exec nginx-proxy nginx -s reload 2>/dev/null || true
    fi
done

echo "✅ SSL certificate check complete"
