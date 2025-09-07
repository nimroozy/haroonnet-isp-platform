import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import customerReducer from './slices/customerSlice';
import billingReducer from './slices/billingSlice';
import ticketReducer from './slices/ticketSlice';
import salesReducer from './slices/salesSlice';
import nocReducer from './slices/nocSlice';
import radiusReducer from './slices/radiusSlice';
import notificationReducer from './slices/notificationSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    customers: customerReducer,
    billing: billingReducer,
    tickets: ticketReducer,
    sales: salesReducer,
    noc: nocReducer,
    radius: radiusReducer,
    notifications: notificationReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['auth/login/fulfilled', 'auth/refresh/fulfilled'],
      },
    }),
});

export default store;