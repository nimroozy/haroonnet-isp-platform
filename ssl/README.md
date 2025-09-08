# SSL Certificates Directory

This directory is used to store SSL certificates for the NGINX reverse proxy.

## Setting up SSL Certificates

### For Development (Self-signed certificates)

You can generate self-signed certificates for development:

```bash
# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate signing request
openssl req -new -key server.key -out server.csr

# Generate self-signed certificate
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

### For Production (Let's Encrypt)

For production, use Let's Encrypt certificates:

```bash
# Install certbot
sudo apt-get install certbot

# Generate certificates
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy certificates to this directory
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem server.crt
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem server.key
```

### File Structure

- `server.crt` - SSL certificate file
- `server.key` - Private key file
- `dhparam.pem` - Diffie-Hellman parameters (optional, for enhanced security)

## Important Notes

- Keep private keys secure and never commit them to version control
- Regularly renew certificates (Let's Encrypt certificates expire every 90 days)
- Use strong Diffie-Hellman parameters for better security