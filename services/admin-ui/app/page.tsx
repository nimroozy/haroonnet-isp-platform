'use client'

import { useState } from 'react'

export default function AdminDashboard() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [currentPage, setCurrentPage] = useState('dashboard')

  const renderSidebar = () => (
    <div className="w-64 bg-gradient-to-b from-slate-900 to-slate-800 text-white h-screen fixed left-0 top-0 overflow-y-auto shadow-2xl border-r border-slate-700">
      <div className="p-6 border-b border-slate-700">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg flex items-center justify-center">
            <span className="text-lg font-bold">🌐</span>
          </div>
          <div>
            <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">HaroonNet ISP</h1>
            <p className="text-xs text-slate-400 font-medium">Professional Management</p>
          </div>
        </div>
      </div>

      <nav className="mt-6 px-4">
        <div className="mb-6">
          <h3 className="text-xs uppercase tracking-wide text-slate-400 font-bold mb-3 px-3">Dashboard</h3>
          <ul className="space-y-2">
            <li>
              <button
                onClick={() => setCurrentPage('dashboard')}
                className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${
                  currentPage === 'dashboard'
                    ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg'
                    : 'hover:bg-slate-700/50 text-slate-300'
                }`}
              >
                <span>📊</span><span className="font-medium">Overview</span>
              </button>
            </li>
            <li>
              <button
                onClick={() => setCurrentPage('reports')}
                className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${
                  currentPage === 'reports'
                    ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg'
                    : 'hover:bg-slate-700/50 text-slate-300'
                }`}
              >
                <span>📈</span><span className="font-medium">Reports</span>
              </button>
            </li>
          </ul>
        </div>

        <div className="mb-6">
          <h3 className="text-xs uppercase tracking-wide text-slate-400 font-bold mb-3 px-3">Customers</h3>
          <ul className="space-y-2">
            <li>
              <button onClick={() => setCurrentPage('customers')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'customers' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>👥</span><span className="font-medium">Manage Customers</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('add-customer')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'add-customer' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>➕</span><span className="font-medium">Add Customer</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('packages')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'packages' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>📦</span><span className="font-medium">Service Packages</span>
              </button>
            </li>
          </ul>
        </div>

        <div className="mb-6">
          <h3 className="text-xs uppercase tracking-wide text-slate-400 font-bold mb-3 px-3">Network</h3>
          <ul className="space-y-2">
            <li>
              <button onClick={() => setCurrentPage('nas')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'nas' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>🌐</span><span className="font-medium">NAS Devices</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('radius')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'radius' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>📡</span><span className="font-medium">RADIUS Server</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('usage')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'usage' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>📊</span><span className="font-medium">Network Usage</span>
              </button>
            </li>
          </ul>
        </div>

        <div className="mb-6">
          <h3 className="text-xs uppercase tracking-wide text-slate-400 font-bold mb-3 px-3">Business</h3>
          <ul className="space-y-2">
            <li>
              <button onClick={() => setCurrentPage('billing')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'billing' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>💰</span><span className="font-medium">Billing</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('tickets')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'tickets' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>🎫</span><span className="font-medium">Support Tickets</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('managers')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'managers' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>👨‍💼</span><span className="font-medium">Staff Management</span>
              </button>
            </li>
          </ul>
        </div>

        <div className="mb-6">
          <h3 className="text-xs uppercase tracking-wide text-slate-400 font-bold mb-3 px-3">Settings</h3>
          <ul className="space-y-2">
            <li>
              <button onClick={() => setCurrentPage('sms-config')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'sms-config' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>📱</span><span className="font-medium">SMS Configuration</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('email-config')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'email-config' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>📧</span><span className="font-medium">Email Settings</span>
              </button>
            </li>
            <li>
              <button onClick={() => setCurrentPage('company-settings')} className={`w-full text-left px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 ${currentPage === 'company-settings' ? 'bg-gradient-to-r from-blue-600 to-purple-600 shadow-lg' : 'hover:bg-slate-700/50 text-slate-300'}`}>
                <span>🏢</span><span className="font-medium">Company Settings</span>
              </button>
            </li>
          </ul>
        </div>

        <div className="mb-6">
          <h3 className="text-xs uppercase tracking-wide text-slate-400 font-bold mb-3 px-3">Monitoring</h3>
          <ul className="space-y-2">
            <li>
              <a href="http://64.23.189.11:3002" target="_blank" className="block px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 hover:bg-slate-700/50 text-slate-300">
                <span>📊</span><span className="font-medium">Grafana</span>
              </a>
            </li>
            <li>
              <a href="http://64.23.189.11:9090" target="_blank" className="block px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 hover:bg-slate-700/50 text-slate-300">
                <span>📈</span><span className="font-medium">Prometheus</span>
              </a>
            </li>
            <li>
              <a href="http://64.23.189.11:5555" target="_blank" className="block px-4 py-3 rounded-xl transition duration-200 flex items-center space-x-3 hover:bg-slate-700/50 text-slate-300">
                <span>🌸</span><span className="font-medium">Workers</span>
              </a>
            </li>
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
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {!isLoggedIn ? (
        <div className="min-h-screen flex items-center justify-center p-4">
          <div className="max-w-md w-full">
            {/* Professional Login Card */}
            <div className="bg-white/95 backdrop-blur-sm rounded-2xl shadow-2xl p-8 border border-white/20">
              <div className="text-center mb-8">
                <div className="w-20 h-20 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-3xl text-white">🌐</span>
                </div>
                <h2 className="text-3xl font-bold text-gray-900 mb-2">HaroonNet ISP</h2>
                <p className="text-gray-600 font-medium">Professional Management Platform</p>
                <div className="w-24 h-1 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full mx-auto mt-4"></div>
              </div>

              <form className="space-y-6">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">Email Address</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center">
                      <span className="text-gray-400">📧</span>
                    </div>
                    <input
                      type="email"
                      className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition duration-200"
                      placeholder="admin@haroonnet.com"
                      defaultValue="admin@haroonnet.com"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">Password</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center">
                      <span className="text-gray-400">🔒</span>
                    </div>
                    <input
                      type="password"
                      className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition duration-200"
                      placeholder="Enter your password"
                      defaultValue="admin123"
                    />
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <label className="flex items-center">
                    <input type="checkbox" className="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
                    <span className="ml-2 text-sm text-gray-600">Remember me</span>
                  </label>
                  <a href="#" className="text-sm text-blue-600 hover:text-blue-800 font-medium">Forgot password?</a>
                </div>

                <button
                  type="button"
                  onClick={() => setIsLoggedIn(true)}
                  className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white py-3 px-4 rounded-lg hover:from-blue-700 hover:to-purple-700 transition duration-200 font-semibold shadow-lg transform hover:scale-105"
                >
                  🚀 Login to Admin Panel
                </button>
              </form>

              <div className="mt-8 text-center">
                <div className="bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg p-4 mb-4">
                  <p className="text-sm font-semibold text-gray-700 mb-2">🔑 Default Credentials</p>
                  <p className="text-sm text-gray-600">Email: admin@haroonnet.com</p>
                  <p className="text-sm text-gray-600">Password: admin123</p>
                </div>
                <p className="text-xs text-gray-500">Secure Professional ISP Management System</p>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="flex min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">
          {renderSidebar()}
          <div className="ml-64 flex-1">
            {/* Professional Header */}
            <div className="bg-white shadow-sm border-b border-slate-200">
              <div className="px-8 py-6">
                <div className="flex justify-between items-center">
                  <div>
                    <h1 className="text-3xl font-bold bg-gradient-to-r from-slate-900 to-slate-700 bg-clip-text text-transparent">Professional ISP Management</h1>
                    <p className="text-slate-600 font-medium mt-1">Complete customer, network, and billing management</p>
                  </div>
                  <div className="flex items-center space-x-4">
                    <div className="text-right">
                      <p className="text-sm font-semibold text-slate-700">Administrator</p>
                      <p className="text-xs text-slate-500">admin@haroonnet.com</p>
                    </div>
                    <button onClick={() => setIsLoggedIn(false)} className="bg-gradient-to-r from-red-500 to-red-600 text-white px-6 py-2 rounded-lg hover:from-red-600 hover:to-red-700 transition duration-200 font-medium shadow-lg">
                      Logout
                    </button>
                  </div>
                </div>
              </div>
            </div>

            {/* Main Content */}
            <div className="p-8">
              {renderContent()}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
