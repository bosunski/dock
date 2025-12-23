# Nginx Proxy Configuration Guide

This guide explains how to configure services to run behind the Nginx reverse proxy.

## Why Use Nginx as a Reverse Proxy?

- **Single entry point**: All services accessible through one IP
- **SSL/TLS termination**: Manage certificates in one place
- **Load balancing**: Distribute traffic across multiple backends
- **Path-based routing**: Route by URL path (/api, /app, etc.)
- **Domain-based routing**: Route by hostname (api.example.com)
- **Static file serving**: Serve assets efficiently
- **Security**: Hide backend service details

## Basic Configuration

### 1. Enable Proxy in Service

Edit your service's `deploy.yml`:

```yaml
# services/api/deploy.yml
service:
  name: api
  type: dockerfile

# Enable Nginx proxying
proxy:
  enabled: true
  path: /api
  strip_prefix: true
```

Options:
- `enabled`: Set to `true` to proxy this service
- `path`: URL path where service is accessible (e.g., `/api`)
- `strip_prefix`: If `true`, removes the path prefix before forwarding

### 2. Generate Nginx Configuration

Run the generator script:

```bash
chmod +x scripts/update-nginx.sh
./scripts/update-nginx.sh
```

This reads all `deploy.yml` files and generates `services/nginx/nginx.conf`.

### 3. Review Generated Config

```bash
cat services/nginx/nginx.conf
```

Verify the upstream and location blocks look correct.

### 4. Deploy

```bash
git add services/nginx/nginx.conf
git commit -m "Update nginx configuration"
git push  # Triggers automatic deployment
```

## Configuration Examples

### Example 1: Simple API Backend

```yaml
# services/api/deploy.yml
service:
  name: api
  type: dockerfile

runtime:
  container_port: 3000

targets:
  roles:
    - web

proxy:
  enabled: true
  path: /api
  strip_prefix: true
```

Requests to `http://server/api/users` → `http://api:3000/users`

### Example 2: Web Application

```yaml
# services/webapp/deploy.yml
service:
  name: webapp
  type: compose

targets:
  servers:
    - prod-web-1

proxy:
  enabled: true
  path: /
  strip_prefix: false
```

Requests to `http://server/` → `http://webapp:8080/`

### Example 3: Multiple Backends with Domains

```yaml
# services/nginx/deploy.yml
service:
  name: nginx
  type: compose

nginx:
  backends:
    # API backend
    - name: api
      upstream: api:3000
      domain: api.example.com
      path: /
    
    # Web application
    - name: webapp
      upstream: webapp:8080
      domain: app.example.com
      path: /
    
    # Admin panel
    - name: admin
      upstream: admin:4000
      domain: admin.example.com
      path: /

targets:
  roles:
    - web
```

## Generated Configuration Structure

The generator creates:

```nginx
# Upstream blocks
upstream api {
    server api:3000;
    keepalive 32;
}

# Server blocks
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Advanced Configuration

### Custom Upstream Configuration

For load balancing or custom settings:

```yaml
nginx:
  backends:
    - name: api
      upstream: api:3000
      domain: api.example.com
      path: /
      
      # Custom upstream settings (requires manual nginx.conf edit)
      # - Backup servers
      # - Health checks
      # - Load balancing method
```

Then manually edit `services/nginx/nginx.conf`:

```nginx
upstream api {
    least_conn;  # Load balancing method
    
    server api-1:3000 max_fails=3 fail_timeout=30s;
    server api-2:3000 max_fails=3 fail_timeout=30s;
    server api-3:3000 backup;
    
    keepalive 32;
}
```

### SSL/TLS Configuration

Add SSL certificates and configuration:

```yaml
# services/nginx/docker-compose.yml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
      - ./ssl.conf:/etc/nginx/conf.d/ssl.conf:ro
```

Create `services/nginx/ssl.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name api.example.com;
    return 301 https://$server_name$request_uri;
}
```

### WebSocket Support

For WebSocket connections:

```nginx
location /ws {
    proxy_pass http://websocket_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

### Rate Limiting

Add rate limiting for APIs:

```nginx
# In http block
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# In location block
location /api {
    limit_req zone=api_limit burst=20 nodelay;
    proxy_pass http://api;
}
```

## Testing Nginx Configuration

### Test Locally

```bash
# Start services locally
docker-compose -f services/nginx/docker-compose.yml up -d
docker-compose -f services/api/docker-compose.yml up -d

# Test nginx config syntax
docker exec nginx-proxy nginx -t

# Test endpoints
curl http://localhost/health
curl http://localhost/api/
```

### Test on Staging

```bash
# Deploy to staging
git push

# Wait for deployment
sleep 60

# Test endpoints
curl http://staging-server/health
curl http://staging-server/api/
```

## Troubleshooting

### 502 Bad Gateway

Backend service is not running or not accessible:

```bash
# Check if backend container is running
docker ps | grep api

# Check Docker network
docker network inspect services_network

# Check backend logs
docker logs api

# Verify upstream in nginx
docker exec nginx-proxy cat /etc/nginx/nginx.conf | grep -A5 "upstream api"
```

### 404 Not Found

Path configuration issue:

```bash
# Check location blocks
docker exec nginx-proxy cat /etc/nginx/nginx.conf | grep -A10 "location /api"

# Test with verbose output
curl -v http://server/api/

# Check nginx logs
docker logs nginx-proxy
```

### Configuration Not Updated

```bash
# Regenerate config
./scripts/update-nginx.sh

# Verify changes
git diff services/nginx/nginx.conf

# Force nginx reload
ssh deploy@server "cd /opt/docker/nginx && docker compose restart"
```

## Best Practices

1. **Test locally first**: Always test nginx config before deploying
2. **Use health checks**: Implement `/health` endpoints in all services
3. **Enable logging**: Configure appropriate log levels
4. **Set timeouts**: Configure reasonable timeout values
5. **Secure headers**: Add security headers (HSTS, CSP, etc.)
6. **Monitor logs**: Regularly check nginx access and error logs
7. **Version control**: Always commit nginx.conf changes
8. **Document custom changes**: Comment manual modifications to generated config

## Monitoring Nginx

### Check Status

```bash
# Container status
docker ps | grep nginx

# Nginx process
docker exec nginx-proxy ps aux | grep nginx

# Test config
docker exec nginx-proxy nginx -t

# Reload config
docker exec nginx-proxy nginx -s reload
```

### View Logs

```bash
# Real-time logs
docker logs -f nginx-proxy

# Access log
docker exec nginx-proxy tail -f /var/log/nginx/access.log

# Error log
docker exec nginx-proxy tail -f /var/log/nginx/error.log

# Filter for specific path
docker exec nginx-proxy grep "/api" /var/log/nginx/access.log
```

### Metrics

```bash
# Request count by status code
docker exec nginx-proxy awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c

# Top requested URLs
docker exec nginx-proxy awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Response times
docker exec nginx-proxy awk '{print $NF}' /var/log/nginx/access.log | sort -n
```

## Next Steps

- Set up SSL certificates with Let's Encrypt
- Implement caching for static assets
- Configure rate limiting for APIs
- Add basic authentication for admin panels
- Set up log aggregation and monitoring
- Implement A/B testing with nginx
