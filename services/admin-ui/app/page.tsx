'use client'

import { useState } from 'react'

export default function AdminDashboard() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [currentPage, setCurrentPage] = useState('dashboard')

  const renderSidebar = () => (
    <div className="w-64 bg-gray-800 text-white h-screen fixed left-0 top-0 overflow-y-auto">
      <div className="p-4">
        <h1 className="text-xl font-bold">HaroonNet ISP</h1>
        <p className="text-sm text-gray-300">Professional Management</p>
      </div>

      <nav className="mt-8">
        <div className="px-4 py-2">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Dashboard</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('dashboard')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'dashboard' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📊 Overview</button></li>
            <li><button onClick={() => setCurrentPage('reports')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'reports' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📈 Reports</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Customers</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('customers')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'customers' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>👥 Manage Customers</button></li>
            <li><button onClick={() => setCurrentPage('add-customer')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'add-customer' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>➕ Add Customer</button></li>
            <li><button onClick={() => setCurrentPage('packages')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'packages' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📦 Service Packages</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Network</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('nas')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'nas' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>🌐 NAS Devices</button></li>
            <li><button onClick={() => setCurrentPage('radius')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'radius' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📡 RADIUS Server</button></li>
            <li><button onClick={() => setCurrentPage('usage')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'usage' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📊 Network Usage</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Business</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('billing')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'billing' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>💰 Billing</button></li>
            <li><button onClick={() => setCurrentPage('tickets')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'tickets' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>🎫 Support Tickets</button></li>
            <li><button onClick={() => setCurrentPage('managers')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'managers' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>👨‍💼 Staff Management</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Settings</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('sms-config')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'sms-config' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📱 SMS Configuration</button></li>
            <li><button onClick={() => setCurrentPage('email-config')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'email-config' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📧 Email Settings</button></li>
            <li><button onClick={() => setCurrentPage('company-settings')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'company-settings' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>🏢 Company Settings</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Monitoring</h3>
          <ul className="mt-2 space-y-1">
            <li><a href="http://167.172.214.191:3002" target="_blank" className="block px-3 py-2 rounded hover:bg-gray-700">📊 Grafana</a></li>
            <li><a href="http://167.172.214.191:9090" target="_blank" className="block px-3 py-2 rounded hover:bg-gray-700">📈 Prometheus</a></li>
            <li><a href="http://167.172.214.191:5555" target="_blank" className="block px-3 py-2 rounded hover:bg-gray-700">🌸 Workers</a></li>
          </ul>
        </div>
      </nav>
    </div>
  )

  const renderSMSConfig = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">SMS Configuration</h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Twilio Configuration */}
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">📱 Twilio SMS Configuration</h3>
          <form className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Account SID</label>
              <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="AC1234567890abcdef..." />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Auth Token</label>
              <input type="password" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="Your auth token" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">From Number</label>
              <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="+1234567890" />
            </div>
            <div className="flex items-center">
              <input type="checkbox" className="mr-2" />
              <label className="text-sm text-gray-700">Enable Twilio SMS</label>
            </div>
            <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
              Save Twilio Settings
            </button>
          </form>
        </div>

        {/* HTTP SMS Configuration */}
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">🌐 HTTP SMS Gateway Configuration</h3>
          <form className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Gateway URL</label>
              <input type="url" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="https://api.smsgateway.com/send" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
              <input type="password" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="Your API key" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Username</label>
              <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="Gateway username" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input type="password" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="Gateway password" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Sender ID</label>
              <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="HaroonNet" />
            </div>
            <div className="flex items-center">
              <input type="checkbox" className="mr-2" />
              <label className="text-sm text-gray-700">Enable HTTP SMS Gateway</label>
            </div>
            <button type="submit" className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700">
              Save HTTP SMS Settings
            </button>
          </form>
        </div>
      </div>

      {/* SMS Test Section */}
      <div className="mt-6 bg-white p-6 rounded-lg shadow-md">
        <h3 className="text-xl font-bold mb-4">📲 Test SMS Configuration</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Test Phone Number</label>
            <input type="tel" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="+93-123-456-789" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Test Message</label>
            <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="Test message from HaroonNet ISP" />
          </div>
        </div>
        <div className="mt-4 space-x-2">
          <button className="bg-purple-600 text-white px-4 py-2 rounded-md hover:bg-purple-700">
            Test Twilio SMS
          </button>
          <button className="bg-orange-600 text-white px-4 py-2 rounded-md hover:bg-orange-700">
            Test HTTP SMS
          </button>
        </div>
      </div>
    </div>
  )

  const renderReports = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">📈 ISP Reports & Analytics</h2>

      {/* Report Categories */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-bold mb-4">💰 Financial Reports</h3>
          <div className="space-y-2">
            <button className="w-full text-left p-2 bg-blue-50 rounded hover:bg-blue-100">📊 Revenue Report</button>
            <button className="w-full text-left p-2 bg-blue-50 rounded hover:bg-blue-100">💳 Payment Report</button>
            <button className="w-full text-left p-2 bg-blue-50 rounded hover:bg-blue-100">📄 Invoice Report</button>
            <button className="w-full text-left p-2 bg-blue-50 rounded hover:bg-blue-100">💸 Outstanding Report</button>
            <button className="w-full text-left p-2 bg-blue-50 rounded hover:bg-blue-100">📈 Profit/Loss Report</button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-bold mb-4">👥 Customer Reports</h3>
          <div className="space-y-2">
            <button className="w-full text-left p-2 bg-green-50 rounded hover:bg-green-100">📋 Customer List</button>
            <button className="w-full text-left p-2 bg-green-50 rounded hover:bg-green-100">📊 Usage Report</button>
            <button className="w-full text-left p-2 bg-green-50 rounded hover:bg-green-100">🔄 Active Sessions</button>
            <button className="w-full text-left p-2 bg-green-50 rounded hover:bg-green-100">⏰ Login History</button>
            <button className="w-full text-left p-2 bg-green-50 rounded hover:bg-green-100">📈 Growth Report</button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-bold mb-4">🌐 Network Reports</h3>
          <div className="space-y-2">
            <button className="w-full text-left p-2 bg-purple-50 rounded hover:bg-purple-100">📡 NAS Status Report</button>
            <button className="w-full text-left p-2 bg-purple-50 rounded hover:bg-purple-100">📊 Bandwidth Usage</button>
            <button className="w-full text-left p-2 bg-purple-50 rounded hover:bg-purple-100">🔍 RADIUS Logs</button>
            <button className="w-full text-left p-2 bg-purple-50 rounded hover:bg-purple-100">⚡ Performance Report</button>
            <button className="w-full text-left p-2 bg-purple-50 rounded hover:bg-purple-100">🚨 Alert History</button>
          </div>
        </div>
      </div>

      {/* Sample Reports Display */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">📊 Monthly Revenue Report</h3>
          <div className="space-y-4">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span>January 2025</span>
              <span className="font-bold text-green-600">$45,230</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span>December 2024</span>
              <span className="font-bold text-blue-600">$42,150</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span>November 2024</span>
              <span className="font-bold text-blue-600">$38,920</span>
            </div>
            <div className="mt-4 p-3 bg-green-50 rounded">
              <p className="text-sm"><strong>Growth:</strong> +8% month-over-month</p>
              <p className="text-sm"><strong>Annual:</strong> $487,560 projected</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">👥 Customer Usage Report</h3>
          <div className="space-y-4">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">Top User: John Doe</p>
                <p className="text-sm text-gray-500">Premium Plan</p>
              </div>
              <span className="font-bold">45.2 GB</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">Sarah Smith</p>
                <p className="text-sm text-gray-500">Basic Plan</p>
              </div>
              <span className="font-bold">28.7 GB</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">Ahmad Khan</p>
                <p className="text-sm text-gray-500">Unlimited Plan</p>
              </div>
              <span className="font-bold">156.3 GB</span>
            </div>
            <div className="mt-4 p-3 bg-blue-50 rounded">
              <p className="text-sm"><strong>Average Usage:</strong> 15.8 GB per customer</p>
              <p className="text-sm"><strong>Peak Hours:</strong> 8:00 PM - 11:00 PM</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderAddCustomer = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">➕ Add New Customer</h2>

      <div className="bg-white p-6 rounded-lg shadow-md">
        <form className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Username *</label>
            <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="customer001" required />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password *</label>
            <input type="password" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="Strong password" required />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Full Name *</label>
            <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="John Doe" required />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
            <input type="email" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="customer@example.com" required />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone *</label>
            <input type="tel" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="+93-123-456-789" required />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Service Package *</label>
            <select className="w-full px-3 py-2 border border-gray-300 rounded-md" required>
              <option value="">Select Package</option>
              <option value="basic">Basic - 10 Mbps ($25/month)</option>
              <option value="premium">Premium - 50 Mbps ($45/month)</option>
              <option value="unlimited">Unlimited - 100 Mbps ($75/month)</option>
            </select>
          </div>

          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
            <textarea className="w-full px-3 py-2 border border-gray-300 rounded-md" rows="3" placeholder="Customer address"></textarea>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Installation Date</label>
            <input type="date" className="w-full px-3 py-2 border border-gray-300 rounded-md" />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Static IP (Optional)</label>
            <input type="text" className="w-full px-3 py-2 border border-gray-300 rounded-md" placeholder="192.168.1.100" />
          </div>

          <div className="md:col-span-2">
            <div className="flex items-center space-x-4">
              <label className="flex items-center">
                <input type="checkbox" className="mr-2" />
                <span className="text-sm text-gray-700">Send welcome SMS</span>
              </label>
              <label className="flex items-center">
                <input type="checkbox" className="mr-2" />
                <span className="text-sm text-gray-700">Send welcome email</span>
              </label>
              <label className="flex items-center">
                <input type="checkbox" className="mr-2" checked />
                <span className="text-sm text-gray-700">Auto-activate account</span>
              </label>
            </div>
          </div>

          <div className="md:col-span-2">
            <button type="submit" className="bg-blue-600 text-white px-6 py-3 rounded-md hover:bg-blue-700 mr-4">
              ➕ Create Customer
            </button>
            <button type="button" onClick={() => setCurrentPage('customers')} className="bg-gray-600 text-white px-6 py-3 rounded-md hover:bg-gray-700">
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  )

  const renderDashboard = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">📊 ISP Management Dashboard</h2>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-blue-500">
          <h3 className="text-lg font-semibold text-gray-700">Total Customers</h3>
          <p className="text-3xl font-bold text-blue-600">1,247</p>
          <p className="text-sm text-green-600">+12% from last month</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-green-500">
          <h3 className="text-lg font-semibold text-gray-700">Active Sessions</h3>
          <p className="text-3xl font-bold text-green-600">892</p>
          <p className="text-sm text-gray-500">Currently online</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-purple-500">
          <h3 className="text-lg font-semibold text-gray-700">Monthly Revenue</h3>
          <p className="text-3xl font-bold text-purple-600">$45,230</p>
          <p className="text-sm text-green-600">+8% growth</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-orange-500">
          <h3 className="text-lg font-semibold text-gray-700">Network Usage</h3>
          <p className="text-3xl font-bold text-orange-600">2.4 TB</p>
          <p className="text-sm text-gray-500">This month</p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">⚡ Quick Actions</h3>
          <div className="space-y-3">
            <button onClick={() => setCurrentPage('add-customer')} className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
              ➕ Add New Customer
            </button>
            <button onClick={() => setCurrentPage('packages')} className="w-full text-left p-3 bg-green-50 rounded hover:bg-green-100 transition duration-200">
              📦 Create Service Package
            </button>
            <button onClick={() => setCurrentPage('nas')} className="w-full text-left p-3 bg-purple-50 rounded hover:bg-purple-100 transition duration-200">
              🌐 Add NAS Device
            </button>
            <button onClick={() => setCurrentPage('billing')} className="w-full text-left p-3 bg-yellow-50 rounded hover:bg-yellow-100 transition duration-200">
              💰 Generate Invoices
            </button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">🔧 System Status</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span>RADIUS Server</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-sm">Online</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Database</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-sm">Connected</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Billing System</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-sm">Active</span>
            </div>
            <div className="flex justify-between items-center">
              <span>SMS Gateway</span>
              <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm">Configure</span>
            </div>
          </div>
          <button onClick={() => setCurrentPage('sms-config')} className="mt-4 bg-blue-600 text-white px-4 py-2 rounded w-full">
            Configure SMS
          </button>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">📋 Recent Activities</h3>
          <div className="space-y-3">
            <div className="text-sm">
              <p className="font-medium">New customer: Ahmad Khan</p>
              <p className="text-gray-500">Premium plan - 2 hours ago</p>
            </div>
            <div className="text-sm">
              <p className="font-medium">Payment received: $45</p>
              <p className="text-gray-500">John Doe - 4 hours ago</p>
            </div>
            <div className="text-sm">
              <p className="font-medium">Support ticket resolved</p>
              <p className="text-gray-500">Ticket #TKT-001 - 6 hours ago</p>
            </div>
            <div className="text-sm">
              <p className="font-medium">NAS device restarted</p>
              <p className="text-gray-500">Router #2 - 8 hours ago</p>
            </div>
          </div>
        </div>
      </div>

      {/* Performance Charts Placeholder */}
      <div className="bg-white p-6 rounded-lg shadow-md">
        <h3 className="text-xl font-bold mb-4">📈 Network Performance (Last 24 Hours)</h3>
        <div className="h-64 bg-gray-50 rounded flex items-center justify-center">
          <div className="text-center">
            <p className="text-gray-500 mb-2">Network Usage Chart</p>
            <p className="text-sm text-gray-400">Peak: 89% at 9:30 PM</p>
            <p className="text-sm text-gray-400">Average: 67% utilization</p>
            <p className="text-sm text-gray-400">Connected Users: 892 active</p>
          </div>
        </div>
      </div>
    </div>
  )

  // ... (keeping the other render functions from before: renderCustomers, renderNAS, renderPackages, renderBilling, renderTickets, renderRADIUS)

  const renderCustomers = () => (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">👥 Customer Management</h2>
        <div className="space-x-2">
          <button onClick={() => setCurrentPage('add-customer')} className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
            ➕ Add Customer
          </button>
          <button className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700">
            📊 Export Report
          </button>
        </div>
      </div>

      {/* Customer Filters */}
      <div className="bg-white p-4 rounded-lg shadow-md mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <input type="text" placeholder="Search customers..." className="px-3 py-2 border border-gray-300 rounded-md" />
          <select className="px-3 py-2 border border-gray-300 rounded-md">
            <option>All Status</option>
            <option>Active</option>
            <option>Suspended</option>
            <option>Inactive</option>
          </select>
          <select className="px-3 py-2 border border-gray-300 rounded-md">
            <option>All Packages</option>
            <option>Basic</option>
            <option>Premium</option>
            <option>Unlimited</option>
          </select>
          <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
            🔍 Filter
          </button>
        </div>
      </div>

      {/* Customer Table */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Package</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Usage</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Last Payment</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <tr>
              <td className="px-6 py-4 whitespace-nowrap">
                <div>
                  <div className="text-sm font-medium text-gray-900">John Doe</div>
                  <div className="text-sm text-gray-500">john@example.com</div>
                  <div className="text-sm text-gray-500">+93-123-456-789</div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">Premium 50MB</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Active</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="text-sm text-gray-900">15.2 GB</div>
                <div className="text-sm text-gray-500">3% of limit</div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">Jan 15, 2025</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                <button className="text-blue-600 hover:text-blue-900">Edit</button>
                <button className="text-yellow-600 hover:text-yellow-900">Suspend</button>
                <button className="text-green-600 hover:text-green-900">Bill</button>
                <button className="text-purple-600 hover:text-purple-900">Usage</button>
              </td>
            </tr>
            <tr>
              <td className="px-6 py-4 whitespace-nowrap">
                <div>
                  <div className="text-sm font-medium text-gray-900">Sarah Smith</div>
                  <div className="text-sm text-gray-500">sarah@example.com</div>
                  <div className="text-sm text-gray-500">+93-987-654-321</div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">Basic 10MB</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">Suspended</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="text-sm text-gray-900">8.7 GB</div>
                <div className="text-sm text-gray-500">9% of limit</div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-red-600">Overdue</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                <button className="text-blue-600 hover:text-blue-900">Edit</button>
                <button className="text-green-600 hover:text-green-900">Activate</button>
                <button className="text-red-600 hover:text-red-900">Collect</button>
                <button className="text-purple-600 hover:text-purple-900">SMS</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  )

  const renderContent = () => {
    switch(currentPage) {
      case 'customers': return renderCustomers()
      case 'add-customer': return renderAddCustomer()
      case 'reports': return renderReports()
      case 'sms-config': return renderSMSConfig()
      case 'nas': return <div className="text-center p-8"><h2 className="text-2xl">🌐 NAS Device Management</h2><p>Manage your Mikrotik routers and network devices</p></div>
      case 'packages': return <div className="text-center p-8"><h2 className="text-2xl">📦 Service Packages</h2><p>Create and manage internet service packages</p></div>
      case 'billing': return <div className="text-center p-8"><h2 className="text-2xl">💰 Billing Department</h2><p>Manage invoices, payments, and billing</p></div>
      case 'tickets': return <div className="text-center p-8"><h2 className="text-2xl">🎫 Support Tickets</h2><p>Manage customer support requests</p></div>
      case 'radius': return <div className="text-center p-8"><h2 className="text-2xl">📡 RADIUS Server</h2><p>Manage authentication server</p></div>
      default: return renderDashboard()
    }
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {!isLoggedIn ? (
        <div className="min-h-screen flex items-center justify-center">
          <div className="max-w-md w-full bg-white rounded-lg shadow-md p-8">
            <div className="text-center mb-6">
              <h2 className="text-3xl font-bold text-gray-900">HaroonNet ISP</h2>
              <p className="text-gray-600">Professional Management Platform</p>
            </div>
            <form className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                <input type="email" className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="admin@haroonnet.com" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Enter your password" />
              </div>
              <button type="button" onClick={() => setIsLoggedIn(true)} className="w-full bg-blue-600 text-white py-3 px-4 rounded-md hover:bg-blue-700 transition duration-200 font-medium">
                Login to Admin Panel
              </button>
            </form>
            <div className="mt-6 text-center text-sm text-gray-500">
              <p>Professional ISP Management Platform</p>
              <p>Default: admin@haroonnet.com / admin123</p>
            </div>
          </div>
        </div>
      ) : (
        <div className="flex">
          {renderSidebar()}
          <div className="ml-64 flex-1 p-8">
            <div className="flex justify-between items-center mb-8">
              <div>
                <h1 className="text-3xl font-bold text-gray-900">Professional ISP Management</h1>
                <p className="text-gray-600">Complete customer, network, and billing management</p>
              </div>
              <button onClick={() => setIsLoggedIn(false)} className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700">
                Logout
              </button>
            </div>
            {renderContent()}
          </div>
        </div>
      )}
    </div>
  )
}
