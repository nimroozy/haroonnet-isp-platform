#!/bin/bash

# Quick Fix for Connection Issues
# Run this on your server to diagnose and fix access problems

echo "🔧 Quick Diagnostic and Fix for HaroonNet ISP Platform"
echo "====================================================="

# Check current directory
if [[ ! -f "docker-compose.yml" ]]; then
    echo "❌ Error: Run this script from /opt/haroonnet directory"
    echo "📍 Current directory: $(pwd)"
    echo "🔄 Change to: cd /opt/haroonnet"
    exit 1
fi

echo "✅ Running from correct directory: $(pwd)"
echo ""

# 1. Check container status
echo "🐳 Container Status:"
echo "==================="
docker-compose ps
echo ""

# 2. Check what ports are actually listening
echo "🌐 Listening Ports:"
echo "=================="
netstat -tlnp | grep -E ':(3000|3001|4000|3002|9090|5555)' || echo "❌ No web service ports found listening"
echo ""

# 3. Test internal connectivity
echo "🔍 Testing Internal Connectivity:"
echo "================================="
curl -I http://localhost:3000 2>/dev/null && echo "✅ Admin UI responding internally" || echo "❌ Admin UI not responding"
curl -I http://localhost:4000/health 2>/dev/null && echo "✅ API responding internally" || echo "❌ API not responding"
curl -I http://localhost:3001 2>/dev/null && echo "✅ Customer Portal responding internally" || echo "❌ Customer Portal not responding"
echo ""

# 4. Check firewall
echo "🛡️ Firewall Status:"
echo "=================="
ufw status numbered
echo ""

# 5. Quick fixes
echo "🔧 Applying Quick Fixes:"
echo "======================="

# Fix 1: Restart web services
echo "🔄 Restarting web services..."
docker-compose restart admin-ui customer-portal api nginx 2>/dev/null || true
sleep 10

# Fix 2: Ensure firewall allows external access
echo "🛡️ Configuring firewall for external access..."
ufw allow 3000/tcp 2>/dev/null || true
ufw allow 3001/tcp 2>/dev/null || true
ufw allow 4000/tcp 2>/dev/null || true
ufw allow 3002/tcp 2>/dev/null || true
ufw reload 2>/dev/null || true

# Fix 3: Check if services are bound to 0.0.0.0
echo "🔍 Checking service binding..."
docker-compose logs admin-ui 2>/dev/null | tail -5
echo ""

# 6. Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📍 Server IP: $SERVER_IP"
echo ""

# 7. Final test
echo "🧪 Final Connectivity Test:"
echo "=========================="
sleep 5
curl -I http://localhost:3000 2>/dev/null && echo "✅ Admin UI working internally" || echo "❌ Admin UI still not working"
echo ""

# 8. Manual test commands
echo "🔧 Manual Test Commands:"
echo "======================="
echo "Test from server:"
echo "  curl -I http://localhost:3000"
echo "  curl -I http://localhost:4000/health"
echo ""
echo "Test from outside:"
echo "  curl -I http://$SERVER_IP:3000"
echo ""
echo "Check container logs:"
echo "  docker-compose logs admin-ui"
echo "  docker-compose logs api"
echo ""
echo "Restart specific service:"
echo "  docker-compose restart admin-ui"
echo ""

# 9. Alternative solution
echo "🆘 If Still Not Working:"
echo "======================="
echo ""
echo "Option 1 - Complete restart:"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo ""
echo "Option 2 - Fresh installation:"
echo "  ./scripts/complete-cleanup.sh"
echo "  curl -sSL https://raw.githubusercontent.com/nimroozy/haroonnet-isp-platform/main/install-isp-platform.sh | bash"
echo ""

echo "✅ Quick fix completed!"
echo ""
echo "🌐 Try accessing: http://$SERVER_IP:3000"
