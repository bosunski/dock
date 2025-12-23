#!/bin/bash
set -e

echo "🔐 Initializing SSL certificates..."

# Check if we're on the server (not in GitHub Actions)
if [ ! -f /opt/docker/nginx/docker-compose.yml ]; then
    echo "Not on server, skipping SSL initialization"
    exit 0
fi

cd /opt/docker/nginx

# Get list of domains from nginx config (excluding _ and localhost)
DOMAINS=$(grep -oP 'server_name \K[^;]+' nginx.conf 2>/dev/null | grep -v '_' | grep -v 'localhost' | sort -u || true)

if [ -z "$DOMAINS" ]; then
    echo "No domains configured, skipping SSL setup"
    exit 0
fi

echo "Found domains: $DOMAINS"

# Check if any domain needs certificates
NEEDS_CERTS=false
for domain in $DOMAINS; do
    domain=$(echo "$domain" | xargs)  # Trim whitespace
    if [ ! -f "/var/lib/docker/volumes/nginx_certbot_certs/_data/live/$domain/fullchain.pem" ]; then
        NEEDS_CERTS=true
        echo "⚠ No certificate for $domain"
    else
        echo "✓ Certificate exists for $domain"
    fi
done

if [ "$NEEDS_CERTS" = false ]; then
    echo "✅ All certificates exist"
    exit 0
fi

echo ""
echo "📝 Generating temporary HTTP-only nginx config..."

# Backup current config
cp nginx.conf nginx.conf.https.bak

# Generate temporary HTTP-only config
cat > nginx.conf.http << 'HTTPCONF'
# Temporary HTTP-only configuration for initial certificate generation
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    
    # Use Docker's internal DNS for runtime resolution
    resolver 127.0.0.11 valid=10s;
    resolver_timeout 5s;
    
    server {
        listen 80 default_server;
        server_name _;
        
        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # ACME challenge for Let's Encrypt
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        # Temporary message for other requests
        location / {
            return 503 "SSL certificates are being generated. Please wait a moment...\n";
            add_header Content-Type text/plain;
        }
    }
}
HTTPCONF

# Use HTTP-only config
cp nginx.conf.http nginx.conf

echo "🔄 Restarting nginx with HTTP-only config..."
docker compose up -d --force-recreate nginx

# Wait for nginx to be ready
sleep 5

echo ""
echo "🔐 Requesting SSL certificates..."

# Request certificates for each domain
for domain in $DOMAINS; do
    domain=$(echo "$domain" | xargs)
    
    if [ -z "$domain" ] || [ "$domain" = "_" ]; then
        continue
    fi
    
    echo ""
    echo "Requesting certificate for: $domain"
    
    docker compose run --rm certbot certonly \
        --webroot \
        -w /var/www/certbot \
        --email "admin@$domain" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$domain" || {
            echo "❌ Failed to obtain certificate for $domain"
            echo ""
            echo "Troubleshooting:"
            echo "  1. Ensure DNS for $domain points to this server"
            echo "  2. Check that port 80 is accessible from the internet"
            echo "  3. Verify no firewall is blocking connections"
            echo ""
            continue
        }
    
    echo "✅ Certificate obtained for $domain"
done

echo ""
echo "📝 Restoring HTTPS-enabled nginx config..."
cp nginx.conf.https.bak nginx.conf

echo "🔄 Restarting nginx with HTTPS config..."
docker compose up -d --force-recreate nginx

# Wait for nginx to be ready
sleep 5

# Check nginx status
if docker ps | grep -q nginx-proxy; then
    echo ""
    echo "✅ SSL initialization complete! Nginx is running with HTTPS."
    echo ""
    echo "Your sites are now available at:"
    for domain in $DOMAINS; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ] && [ "$domain" != "_" ]; then
            echo "  - https://$domain"
        fi
    done
else
    echo ""
    echo "❌ Nginx failed to start with HTTPS config"
    echo "Reverting to HTTP-only config..."
    cp nginx.conf.http nginx.conf
    docker compose up -d nginx
fi

echo ""
echo "🔄 Starting certbot auto-renewal service..."
docker compose up -d certbot

echo ""
echo "✅ Setup complete!"
