import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  leads: [],
  quotes: [],
  targets: [],
  loading: false,
  error: null,
};

const salesSlice = createSlice({
  name: 'sales',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const { clearError } = salesSlice.actions;
export default salesSlice.reducer;