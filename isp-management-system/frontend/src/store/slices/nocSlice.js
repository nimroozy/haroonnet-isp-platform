import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  devices: [],
  alerts: [],
  metrics: [],
  loading: false,
  error: null,
};

const nocSlice = createSlice({
  name: 'noc',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const { clearError } = nocSlice.actions;
export default nocSlice.reducer;