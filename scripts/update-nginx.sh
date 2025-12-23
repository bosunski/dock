#!/bin/bash
# Helper script to update nginx configuration based on deployed services

set -e

echo "🔧 Generating Nginx configuration from service definitions..."

# Install PyYAML if not present
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "📦 Installing PyYAML..."
    pip3 install PyYAML
fi

# Generate nginx config
python3 scripts/generate-nginx-config.py

echo "✅ Nginx configuration generated successfully!"
echo ""
echo "To apply the configuration:"
echo "  1. Review: cat services/nginx/nginx.conf"
echo "  2. Deploy: docker-compose -f services/nginx/docker-compose.yml up -d --force-recreate"
echo "  3. Or push to trigger automatic deployment"
