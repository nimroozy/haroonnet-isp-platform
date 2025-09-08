#!/bin/bash

# HaroonNet ISP Platform - SSL Certificate Generation Script
# This script generates self-signed SSL certificates for development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$PROJECT_ROOT/ssl"

echo "=== HaroonNet ISP Platform SSL Certificate Generator ==="
echo "Project Root: $PROJECT_ROOT"
echo "SSL Directory: $SSL_DIR"

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Check if certificates already exist
if [ -f "$SSL_DIR/server.crt" ] && [ -f "$SSL_DIR/server.key" ]; then
    echo ""
    read -p "SSL certificates already exist. Regenerate? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing certificates."
        exit 0
    fi
fi

echo ""
echo "Generating self-signed SSL certificates..."

# Generate private key
echo "1. Generating private key..."
openssl genrsa -out "$SSL_DIR/server.key" 2048

# Create certificate configuration
cat > "$SSL_DIR/cert.conf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=AF
ST=Kabul
L=Kabul
O=HaroonNet ISP
OU=IT Department
CN=haroonnet.local

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = haroonnet.local
DNS.2 = localhost
DNS.3 = *.haroonnet.local
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate certificate signing request and certificate
echo "2. Generating certificate..."
openssl req -new -x509 -key "$SSL_DIR/server.key" -out "$SSL_DIR/server.crt" -days 365 -config "$SSL_DIR/cert.conf" -extensions v3_req

# Generate Diffie-Hellman parameters for enhanced security
echo "3. Generating Diffie-Hellman parameters (this may take a while)..."
openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048

# Set appropriate permissions
chmod 600 "$SSL_DIR/server.key"
chmod 644 "$SSL_DIR/server.crt"
chmod 644 "$SSL_DIR/dhparam.pem"

# Clean up temporary files
rm -f "$SSL_DIR/cert.conf"

echo ""
echo "✅ SSL certificates generated successfully!"
echo ""
echo "Files created:"
echo "  - $SSL_DIR/server.key (private key)"
echo "  - $SSL_DIR/server.crt (certificate)"
echo "  - $SSL_DIR/dhparam.pem (DH parameters)"
echo ""
echo "Certificate details:"
openssl x509 -in "$SSL_DIR/server.crt" -text -noout | grep -E "(Subject:|DNS:|IP Address:|Not After)"
echo ""
echo "⚠️  Note: This is a self-signed certificate for development only."
echo "   For production, use certificates from a trusted CA like Let's Encrypt."
echo ""
echo "To trust this certificate in your browser:"
echo "  1. Navigate to https://localhost"
echo "  2. Click 'Advanced' -> 'Proceed to localhost (unsafe)'"
echo "  3. Or add the certificate to your system's trusted store"
echo ""