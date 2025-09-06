FROM ubuntu:24.04

# Install FreeRADIUS and dependencies
RUN apt-get update && \
    apt-get install -y \
    freeradius \
    freeradius-mysql \
    freeradius-utils \
    mysql-client \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/freeradius/3.0/certs \
    && mkdir -p /var/log/freeradius \
    && chown -R freerad:freerad /var/log/freeradius

# Copy configuration files
COPY config/ /etc/freeradius/3.0/
COPY scripts/ /opt/freeradius/

# Set permissions
RUN chown -R freerad:freerad /etc/freeradius/3.0 \
    && chmod +x /opt/freeradius/*.sh

# Expose ports
EXPOSE 1812/udp 1813/udp 3799/udp

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD radtest test test123 localhost 1812 testing123 || exit 1

# Start script
CMD ["/opt/freeradius/start.sh"]
