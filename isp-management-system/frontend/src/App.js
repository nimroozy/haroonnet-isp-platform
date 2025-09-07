import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { SnackbarProvider } from 'notistack';
import { Provider } from 'react-redux';
import { QueryClient, QueryClientProvider } from 'react-query';

// Store
import { store } from './store/store';

// Layout
import MainLayout from './components/Layout/MainLayout';
import AuthLayout from './components/Layout/AuthLayout';

// Auth Pages
import Login from './pages/Auth/Login';
import ForgotPassword from './pages/Auth/ForgotPassword';

// Dashboard
import Dashboard from './pages/Dashboard/Dashboard';

// Customer Management
import Customers from './pages/Customers/Customers';
import CustomerDetail from './pages/Customers/CustomerDetail';
import AddCustomer from './pages/Customers/AddCustomer';

// Billing
import Invoices from './pages/Billing/Invoices';
import Payments from './pages/Billing/Payments';
import ServicePlans from './pages/Billing/ServicePlans';
import Subscriptions from './pages/Billing/Subscriptions';

// Tickets
import Tickets from './pages/Tickets/Tickets';
import TicketDetail from './pages/Tickets/TicketDetail';
import CreateTicket from './pages/Tickets/CreateTicket';

// Sales
import Leads from './pages/Sales/Leads';
import Quotes from './pages/Sales/Quotes';
import SalesTargets from './pages/Sales/SalesTargets';

// NOC
import NetworkDevices from './pages/NOC/NetworkDevices';
import NetworkMap from './pages/NOC/NetworkMap';
import Alerts from './pages/NOC/Alerts';
import Monitoring from './pages/NOC/Monitoring';

// RADIUS
import OnlineUsers from './pages/RADIUS/OnlineUsers';
import RadiusLogs from './pages/RADIUS/RadiusLogs';
import NASDevices from './pages/RADIUS/NASDevices';

// Settings
import Settings from './pages/Settings/Settings';
import UserManagement from './pages/Settings/UserManagement';
import SystemConfig from './pages/Settings/SystemConfig';

// Auth Guard
import PrivateRoute from './components/Auth/PrivateRoute';

// Create theme
const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
      light: '#42a5f5',
      dark: '#1565c0',
    },
    secondary: {
      main: '#dc004e',
      light: '#e33371',
      dark: '#9a0036',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  typography: {
    h1: {
      fontSize: '2.5rem',
      fontWeight: 500,
    },
    h2: {
      fontSize: '2rem',
      fontWeight: 500,
    },
    h3: {
      fontSize: '1.75rem',
      fontWeight: 500,
    },
    h4: {
      fontSize: '1.5rem',
      fontWeight: 500,
    },
    h5: {
      fontSize: '1.25rem',
      fontWeight: 500,
    },
    h6: {
      fontSize: '1rem',
      fontWeight: 500,
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0px 2px 4px rgba(0, 0, 0, 0.1)',
        },
      },
    },
  },
});

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function App() {
  return (
    <Provider store={store}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <SnackbarProvider
            maxSnack={3}
            anchorOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
          >
            <Router>
              <Routes>
                {/* Auth Routes */}
                <Route path="/auth" element={<AuthLayout />}>
                  <Route path="login" element={<Login />} />
                  <Route path="forgot-password" element={<ForgotPassword />} />
                </Route>

                {/* Protected Routes */}
                <Route
                  path="/"
                  element={
                    <PrivateRoute>
                      <MainLayout />
                    </PrivateRoute>
                  }
                >
                  {/* Dashboard */}
                  <Route index element={<Navigate to="/dashboard" replace />} />
                  <Route path="dashboard" element={<Dashboard />} />

                  {/* Customers */}
                  <Route path="customers">
                    <Route index element={<Customers />} />
                    <Route path="add" element={<AddCustomer />} />
                    <Route path=":id" element={<CustomerDetail />} />
                  </Route>

                  {/* Billing */}
                  <Route path="billing">
                    <Route path="invoices" element={<Invoices />} />
                    <Route path="payments" element={<Payments />} />
                    <Route path="plans" element={<ServicePlans />} />
                    <Route path="subscriptions" element={<Subscriptions />} />
                  </Route>

                  {/* Tickets */}
                  <Route path="tickets">
                    <Route index element={<Tickets />} />
                    <Route path="create" element={<CreateTicket />} />
                    <Route path=":id" element={<TicketDetail />} />
                  </Route>

                  {/* Sales */}
                  <Route path="sales">
                    <Route path="leads" element={<Leads />} />
                    <Route path="quotes" element={<Quotes />} />
                    <Route path="targets" element={<SalesTargets />} />
                  </Route>

                  {/* NOC */}
                  <Route path="noc">
                    <Route path="devices" element={<NetworkDevices />} />
                    <Route path="map" element={<NetworkMap />} />
                    <Route path="alerts" element={<Alerts />} />
                    <Route path="monitoring" element={<Monitoring />} />
                  </Route>

                  {/* RADIUS */}
                  <Route path="radius">
                    <Route path="online-users" element={<OnlineUsers />} />
                    <Route path="logs" element={<RadiusLogs />} />
                    <Route path="nas" element={<NASDevices />} />
                  </Route>

                  {/* Settings */}
                  <Route path="settings">
                    <Route index element={<Settings />} />
                    <Route path="users" element={<UserManagement />} />
                    <Route path="system" element={<SystemConfig />} />
                  </Route>
                </Route>

                {/* Redirect to login */}
                <Route path="*" element={<Navigate to="/auth/login" replace />} />
              </Routes>
            </Router>
          </SnackbarProvider>
        </ThemeProvider>
      </QueryClientProvider>
    </Provider>
  );
}

export default App;