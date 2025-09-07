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
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Main</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('dashboard')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'dashboard' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📊 Dashboard</button></li>
            <li><button onClick={() => setCurrentPage('customers')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'customers' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>👥 Customers</button></li>
            <li><button onClick={() => setCurrentPage('packages')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'packages' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📦 Packages</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Network</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('nas')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'nas' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>🌐 NAS Devices</button></li>
            <li><button onClick={() => setCurrentPage('radius')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'radius' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📡 RADIUS Server</button></li>
            <li><button onClick={() => setCurrentPage('usage')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'usage' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>📈 Usage Analytics</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">Business</h3>
          <ul className="mt-2 space-y-1">
            <li><button onClick={() => setCurrentPage('billing')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'billing' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>💰 Billing</button></li>
            <li><button onClick={() => setCurrentPage('tickets')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'tickets' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>🎫 Support Tickets</button></li>
            <li><button onClick={() => setCurrentPage('managers')} className={`w-full text-left px-3 py-2 rounded ${currentPage === 'managers' ? 'bg-blue-600' : 'hover:bg-gray-700'}`}>👨‍💼 Managers</button></li>
          </ul>
        </div>

        <div className="px-4 py-2 mt-6">
          <h3 className="text-xs uppercase tracking-wide text-gray-400 font-semibold">System</h3>
          <ul className="mt-2 space-y-1">
            <li><a href="http://167.172.214.191:3002" target="_blank" className="block px-3 py-2 rounded hover:bg-gray-700">📊 Grafana</a></li>
            <li><a href="http://167.172.214.191:9090" target="_blank" className="block px-3 py-2 rounded hover:bg-gray-700">📈 Prometheus</a></li>
            <li><a href="http://167.172.214.191:5555" target="_blank" className="block px-3 py-2 rounded hover:bg-gray-700">🌸 Workers</a></li>
          </ul>
        </div>
      </nav>
    </div>
  )

  const renderDashboard = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">ISP Dashboard</h2>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-semibold text-gray-700">Total Customers</h3>
          <p className="text-3xl font-bold text-blue-600">1,247</p>
          <p className="text-sm text-green-600">+12% from last month</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-semibold text-gray-700">Active Sessions</h3>
          <p className="text-3xl font-bold text-green-600">892</p>
          <p className="text-sm text-gray-500">Currently online</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-semibold text-gray-700">Monthly Revenue</h3>
          <p className="text-3xl font-bold text-purple-600">$45,230</p>
          <p className="text-sm text-green-600">+8% growth</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-semibold text-gray-700">Network Usage</h3>
          <p className="text-3xl font-bold text-orange-600">2.4 TB</p>
          <p className="text-sm text-gray-500">This month</p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">Quick Actions</h3>
          <div className="space-y-3">
            <button onClick={() => setCurrentPage('customers')} className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
              ➕ Add New Customer
            </button>
            <button onClick={() => setCurrentPage('packages')} className="w-full text-left p-3 bg-green-50 rounded hover:bg-green-100 transition duration-200">
              📦 Create Package
            </button>
            <button onClick={() => setCurrentPage('nas')} className="w-full text-left p-3 bg-purple-50 rounded hover:bg-purple-100 transition duration-200">
              🌐 Add NAS Device
            </button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">System Status</h3>
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
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">Recent Activities</h3>
          <div className="space-y-3">
            <div className="text-sm">
              <p className="font-medium">New customer registration</p>
              <p className="text-gray-500">2 hours ago</p>
            </div>
            <div className="text-sm">
              <p className="font-medium">Payment received: $45</p>
              <p className="text-gray-500">4 hours ago</p>
            </div>
            <div className="text-sm">
              <p className="font-medium">Package upgraded</p>
              <p className="text-gray-500">6 hours ago</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderCustomers = () => (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Customer Management</h2>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
          ➕ Add New Customer
        </button>
      </div>

      {/* Customer Table */}
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Package</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Usage</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <tr>
              <td className="px-6 py-4 whitespace-nowrap">
                <div>
                  <div className="text-sm font-medium text-gray-900">John Doe</div>
                  <div className="text-sm text-gray-500">john@example.com</div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">Premium 50MB</td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Active</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">15.2 GB</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-blue-600 hover:text-blue-900 mr-3">Edit</button>
                <button className="text-red-600 hover:text-red-900">Suspend</button>
              </td>
            </tr>
            <tr>
              <td className="px-6 py-4 whitespace-nowrap">
                <div>
                  <div className="text-sm font-medium text-gray-900">Sarah Smith</div>
                  <div className="text-sm text-gray-500">sarah@example.com</div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">Basic 10MB</td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">Suspended</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">8.7 GB</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-blue-600 hover:text-blue-900 mr-3">Edit</button>
                <button className="text-green-600 hover:text-green-900">Activate</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  )

  const renderNAS = () => (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">NAS Device Management</h2>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
          ➕ Add NAS Device
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-bold mb-4">Mikrotik Router #1</h3>
          <div className="space-y-2">
            <p><strong>IP:</strong> 192.168.1.1</p>
            <p><strong>Type:</strong> Mikrotik RB4011</p>
            <p><strong>Location:</strong> Main Office</p>
            <p><strong>Status:</strong> <span className="text-green-600">Online</span></p>
            <p><strong>Connected Users:</strong> 45</p>
          </div>
          <div className="mt-4 space-x-2">
            <button className="bg-blue-600 text-white px-3 py-1 rounded text-sm">Edit</button>
            <button className="bg-yellow-600 text-white px-3 py-1 rounded text-sm">Restart</button>
            <button className="bg-red-600 text-white px-3 py-1 rounded text-sm">Disable</button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-lg font-bold mb-4">Mikrotik Router #2</h3>
          <div className="space-y-2">
            <p><strong>IP:</strong> 192.168.2.1</p>
            <p><strong>Type:</strong> Mikrotik RB3011</p>
            <p><strong>Location:</strong> Branch Office</p>
            <p><strong>Status:</strong> <span className="text-green-600">Online</span></p>
            <p><strong>Connected Users:</strong> 32</p>
          </div>
          <div className="mt-4 space-x-2">
            <button className="bg-blue-600 text-white px-3 py-1 rounded text-sm">Edit</button>
            <button className="bg-yellow-600 text-white px-3 py-1 rounded text-sm">Restart</button>
            <button className="bg-red-600 text-white px-3 py-1 rounded text-sm">Disable</button>
          </div>
        </div>
      </div>
    </div>
  )

  const renderPackages = () => (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Service Packages</h2>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
          ➕ Create Package
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-blue-500">
          <h3 className="text-xl font-bold mb-2">Basic Plan</h3>
          <p className="text-2xl font-bold text-blue-600 mb-4">$25/month</p>
          <ul className="space-y-2">
            <li>✅ 10 Mbps Download</li>
            <li>✅ 5 Mbps Upload</li>
            <li>✅ 100 GB Data Limit</li>
            <li>✅ Email Support</li>
          </ul>
          <div className="mt-4 space-x-2">
            <button className="bg-blue-600 text-white px-3 py-1 rounded text-sm">Edit</button>
            <button className="bg-red-600 text-white px-3 py-1 rounded text-sm">Delete</button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-green-500">
          <h3 className="text-xl font-bold mb-2">Premium Plan</h3>
          <p className="text-2xl font-bold text-green-600 mb-4">$45/month</p>
          <ul className="space-y-2">
            <li>✅ 50 Mbps Download</li>
            <li>✅ 25 Mbps Upload</li>
            <li>✅ 500 GB Data Limit</li>
            <li>✅ Priority Support</li>
          </ul>
          <div className="mt-4 space-x-2">
            <button className="bg-blue-600 text-white px-3 py-1 rounded text-sm">Edit</button>
            <button className="bg-red-600 text-white px-3 py-1 rounded text-sm">Delete</button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md border-l-4 border-purple-500">
          <h3 className="text-xl font-bold mb-2">Unlimited Plan</h3>
          <p className="text-2xl font-bold text-purple-600 mb-4">$75/month</p>
          <ul className="space-y-2">
            <li>✅ 100 Mbps Download</li>
            <li>✅ 50 Mbps Upload</li>
            <li>✅ Unlimited Data</li>
            <li>✅ 24/7 Phone Support</li>
          </ul>
          <div className="mt-4 space-x-2">
            <button className="bg-blue-600 text-white px-3 py-1 rounded text-sm">Edit</button>
            <button className="bg-red-600 text-white px-3 py-1 rounded text-sm">Delete</button>
          </div>
        </div>
      </div>
    </div>
  )

  const renderBilling = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">Billing Department</h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">Recent Invoices</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">Invoice #INV-001</p>
                <p className="text-sm text-gray-500">John Doe - Premium Plan</p>
              </div>
              <div className="text-right">
                <p className="font-bold">$45.00</p>
                <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs">Paid</span>
              </div>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">Invoice #INV-002</p>
                <p className="text-sm text-gray-500">Sarah Smith - Basic Plan</p>
              </div>
              <div className="text-right">
                <p className="font-bold">$25.00</p>
                <span className="px-2 py-1 bg-red-100 text-red-800 rounded-full text-xs">Overdue</span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">Payment Summary</h3>
          <div className="space-y-4">
            <div className="flex justify-between">
              <span>Total Revenue</span>
              <span className="font-bold">$45,230</span>
            </div>
            <div className="flex justify-between">
              <span>Pending Payments</span>
              <span className="font-bold text-red-600">$2,150</span>
            </div>
            <div className="flex justify-between">
              <span>This Month</span>
              <span className="font-bold text-green-600">$3,890</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderTickets = () => (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Support Tickets</h2>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
          ➕ Create Ticket
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ticket ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <tr>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">#TKT-001</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">John Doe</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">Internet connection slow</td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">High</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">In Progress</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button className="text-blue-600 hover:text-blue-900 mr-3">View</button>
                <button className="text-green-600 hover:text-green-900">Close</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  )

  const renderRADIUS = () => (
    <div>
      <h2 className="text-2xl font-bold mb-6">RADIUS Server Management</h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">Server Status</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span>RADIUS Service</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-sm">Running</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Authentication Port</span>
              <span>1812</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Accounting Port</span>
              <span>1813</span>
            </div>
            <div className="flex justify-between items-center">
              <span>Active Sessions</span>
              <span className="font-bold">892</span>
            </div>
          </div>
          <div className="mt-6 space-x-2">
            <button className="bg-green-600 text-white px-4 py-2 rounded">Restart RADIUS</button>
            <button className="bg-blue-600 text-white px-4 py-2 rounded">View Config</button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h3 className="text-xl font-bold mb-4">Recent Auth Requests</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-2 bg-green-50 rounded">
              <span>john@haroonnet.com</span>
              <span className="text-green-600 text-sm">✅ Accepted</span>
            </div>
            <div className="flex justify-between items-center p-2 bg-green-50 rounded">
              <span>sarah@haroonnet.com</span>
              <span className="text-green-600 text-sm">✅ Accepted</span>
            </div>
            <div className="flex justify-between items-center p-2 bg-red-50 rounded">
              <span>invalid@user.com</span>
              <span className="text-red-600 text-sm">❌ Rejected</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderContent = () => {
    switch(currentPage) {
      case 'customers': return renderCustomers()
      case 'nas': return renderNAS()
      case 'packages': return renderPackages()
      case 'billing': return renderBilling()
      case 'tickets': return renderTickets()
      case 'radius': return renderRADIUS()
      default: return renderDashboard()
    }
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {!isLoggedIn ? (
        <div className="min-h-screen flex items-center justify-center">
          <div className="max-w-md w-full bg-white rounded-lg shadow-md p-8">
            <h2 className="text-2xl font-bold mb-6 text-center">HaroonNet ISP Admin</h2>
            <form className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input type="email" className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="admin@haroonnet.com" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Enter password" />
              </div>
              <button type="button" onClick={() => setIsLoggedIn(true)} className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition duration-200">
                Login to Admin Panel
              </button>
            </form>
          </div>
        </div>
      ) : (
        <div className="flex">
          {renderSidebar()}
          <div className="ml-64 flex-1 p-8">
            <div className="flex justify-between items-center mb-8">
              <h1 className="text-3xl font-bold text-gray-900">ISP Management System</h1>
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
