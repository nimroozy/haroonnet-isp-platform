import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  invoices: [],
  payments: [],
  servicePlans: [],
  subscriptions: [],
  loading: false,
  error: null,
};

const billingSlice = createSlice({
  name: 'billing',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const { clearError } = billingSlice.actions;
export default billingSlice.reducer;