'use client'

import { useState } from 'react'

export default function Home() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)

  return (
    <div className="max-w-4xl mx-auto px-4">
      {!isLoggedIn ? (
        <div className="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
          <h2 className="text-2xl font-bold mb-6 text-center">Customer Login</h2>
          <form className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Username
              </label>
              <input
                type="text"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter your username"
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
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-2xl font-bold mb-4">Welcome to Your Dashboard</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div className="bg-blue-50 p-4 rounded-lg">
                <h3 className="font-semibold text-blue-800">Account Status</h3>
                <p className="text-2xl font-bold text-green-600">Active</p>
              </div>
              <div className="bg-green-50 p-4 rounded-lg">
                <h3 className="font-semibold text-green-800">Current Plan</h3>
                <p className="text-2xl font-bold text-green-600">Premium 100MB</p>
              </div>
              <div className="bg-yellow-50 p-4 rounded-lg">
                <h3 className="font-semibold text-yellow-800">Data Usage</h3>
                <p className="text-2xl font-bold text-yellow-600">45.2 GB</p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="text-xl font-bold mb-4">Recent Bills</h3>
              <div className="space-y-3">
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
                  <span>November 2024</span>
                  <span className="font-semibold text-green-600">$45.00 - Paid</span>
                </div>
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
                  <span>October 2024</span>
                  <span className="font-semibold text-green-600">$45.00 - Paid</span>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="text-xl font-bold mb-4">Support</h3>
              <div className="space-y-3">
                <button className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
                  📧 Contact Support
                </button>
                <button className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
                  📞 Request Callback
                </button>
                <button className="w-full text-left p-3 bg-blue-50 rounded hover:bg-blue-100 transition duration-200">
                  🎫 Open Ticket
                </button>
              </div>
            </div>
          </div>

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
