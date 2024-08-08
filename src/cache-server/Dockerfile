FROM nginx:latest

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy TLS certificates
COPY tls-nginx /etc/nginx/tls

# Expose port 443 for HTTPS
EXPOSE 443
