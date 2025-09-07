'use client'

import { useState } from 'react'

export default function AdminDashboard() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)

  return (
    <div className="max-w-6xl mx-auto px-4">
      {!isLoggedIn ? (
        <div className="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
          <h2 className="text-2xl font-bold mb-6 text-center">Admin Login</h2>
          <form className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                type="email"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="admin@haroonnet.com"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <input
                type="password"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter your password"
              />
            </div>
            <button
              type="button"
              onClick={() => setIsLoggedIn(true)}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition duration-200"
            >
              Login
            </button>
          </form>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Dashboard Stats */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-semibold text-gray-700">Total Customers</h3>
              <p className="text-3xl font-bold text-blue-600">1,247</p>
              <p className="text-sm text-gray-500">+12% from last month</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-semibold text-gray-700">Active Sessions</h3>
              <p className="text-3xl font-bold text-green-600">892</p>
              <p className="text-sm text-gray-500">Currently online</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-lg font-semibold text-gray-700">Monthly Revenue</h3>
              <p className="text-3xl font-bold text-purple-600">$45,230</p>
              <p className="text-sm text-gray-500">+8% from last month</p>
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
              <h3 className="text-xl font-bold mb-4">Customer Management</h3>
              <div className="space-y-3">
                <button className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
                  👥 View All Customers
                </button>
                <button className="w-full text-left p-3 bg-green-50 rounded hover:bg-green-100 transition duration-200">
                  ➕ Add New Customer
                </button>
                <button className="w-full text-left p-3 bg-yellow-50 rounded hover:bg-yellow-100 transition duration-200">
                  📊 Customer Reports
                </button>
              </div>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-xl font-bold mb-4">Network Management</h3>
              <div className="space-y-3">
                <button className="w-full text-left p-3 bg-purple-50 rounded hover:bg-purple-100 transition duration-200">
                  🌐 NAS Devices
                </button>
                <button className="w-full text-left p-3 bg-indigo-50 rounded hover:bg-indigo-100 transition duration-200">
                  📡 Service Plans
                </button>
                <button className="w-full text-left p-3 bg-pink-50 rounded hover:bg-pink-100 transition duration-200">
                  🔧 RADIUS Settings
                </button>
              </div>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-md">
              <h3 className="text-xl font-bold mb-4">Billing & Reports</h3>
              <div className="space-y-3">
                <button className="w-full text-left p-3 bg-green-50 rounded hover:bg-green-100 transition duration-200">
                  💰 Billing Management
                </button>
                <button className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
                  📈 Usage Reports
                </button>
                <button className="w-full text-left p-3 bg-orange-50 rounded hover:bg-orange-100 transition duration-200">
                  💳 Payment History
                </button>
              </div>
            </div>
          </div>

          {/* Recent Activity */}
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h3 className="text-xl font-bold mb-4">Recent Activity</h3>
            <div className="space-y-3">
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
                <span>New customer registration: John Doe</span>
                <span className="text-sm text-gray-500">2 hours ago</span>
              </div>
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
                <span>Payment received: Customer #1234</span>
                <span className="text-sm text-gray-500">4 hours ago</span>
              </div>
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
                <span>Service plan updated: Premium 100MB</span>
                <span className="text-sm text-gray-500">6 hours ago</span>
              </div>
            </div>
          </div>

          {/* Logout */}
          <div className="text-center">
            <button
              onClick={() => setIsLoggedIn(false)}
              className="bg-red-600 text-white py-2 px-6 rounded-md hover:bg-red-700 transition duration-200"
            >
              Logout
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
