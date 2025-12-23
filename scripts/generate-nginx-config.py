#!/usr/bin/env python3
"""
Generate Nginx configuration dynamically based on service deploy.yml files
"""

import os
import yaml
from pathlib import Path

def load_service_configs():
    """Load all service deploy.yml configurations"""
    services_dir = Path('services')
    configs = []
    
    for service_path in services_dir.iterdir():
        if not service_path.is_dir():
            continue
            
        deploy_file = service_path / 'deploy.yml'
        if not deploy_file.exists():
            continue
            
        with open(deploy_file) as f:
            config = yaml.safe_load(f)
            
        # Only include services that should be behind nginx
        if config.get('proxy', {}).get('enabled', False):
            configs.append({
                'name': config['service']['name'],
                'config': config
            })
    
    return configs

def generate_upstream_config(service_name, upstream):
    """Generate upstream block for a service"""
    # Don't use upstream blocks - we'll use variables with resolver instead
    return ""

def generate_location_config(service_name, path, upstream, strip_prefix=False):
    """Generate location block for a service with runtime DNS resolution"""
    proxy_pass_path = ""
    if strip_prefix and path != "/":
        proxy_pass_path = "/"
    
    return f"""
        location {path} {{
            # Use variable to force runtime DNS resolution
            set $upstream_{service_name.replace('-', '_')} {upstream};
            proxy_pass http://$upstream_{service_name.replace('-', '_')}{proxy_pass_path};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }}
"""

def generate_nginx_config():
    """Generate complete nginx configuration"""
    services = load_service_configs()
    
    if not services:
        print("No services with proxy enabled found")
        return
    
    config = """# Auto-generated Nginx configuration
# Generated from service deploy.yml files

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;
    
    # Use Docker's internal DNS for runtime resolution
    resolver 127.0.0.11 valid=10s;
    resolver_timeout 5s;
    
"""
    
    # Skip upstream blocks - using variables with resolver instead
    
    # Health check endpoint
    config += """
    # Health check endpoint
    server {
        listen 80;
        server_name _;
        
        location /health {
            access_log off;
            return 200 "healthy\\n";
            add_header Content-Type text/plain;
        }
    }
    
"""
    
    # Generate server blocks grouped by domain
    domains = {}
    for service in services:
        name = service['name']
        proxy_config = service['config'].get('proxy', {})
        backends = service['config'].get('nginx', {}).get('backends', [])
        
        if backends:
            for backend in backends:
                domain = backend.get('domain', '_')
                if domain not in domains:
                    domains[domain] = []
                
                # Calculate upstream address
                runtime = service['config'].get('runtime', {})
                port = runtime.get('container_port', 8080)
                upstream = backend.get('upstream', f"{backend['name']}:{port}")
                
                domains[domain].append({
                    'name': backend['name'],
                    'upstream': upstream,
                    'path': backend.get('path', '/'),
                    'strip_prefix': False
                })
        else:
            # Default domain configuration
            domain = proxy_config.get('domain', '_')
            if domain not in domains:
                domains[domain] = []
            
            # Calculate upstream address
            runtime = service['config'].get('runtime', {})
            port = runtime.get('container_port', 8080)
            upstream = f"{name}:{port}"
            
            domains[domain].append({
                'name': service['name'],
                'upstream': upstream,
                'path': proxy_config.get('path', '/'),
                'strip_prefix': proxy_config.get('strip_prefix', False)
            })
    
    # Generate server blocks
    for domain, locations in domains.items():
        config += f"""
    server {{
        listen 80;
        server_name {domain};
        
        client_max_body_size 50M;
"""
        
        for location in locations:
            config += generate_location_config(
                location['name'],
                location['path'],
                location['upstream'],
                location['strip_prefix']
            )
        
        config += """
    }
"""
    
    config += "}\n"
    
    return config

if __name__ == '__main__':
    config = generate_nginx_config()
    if config:
        # Write to nginx config file
        output_path = Path('services/nginx/nginx.conf')
        with open(output_path, 'w') as f:
            f.write(config)
        print(f"✅ Generated nginx configuration: {output_path}")
        print("\n" + config)
