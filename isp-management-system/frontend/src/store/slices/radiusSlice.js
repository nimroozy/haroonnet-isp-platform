import { createSlice } from '@reduxjs/toolkit';

const initialState = {
  onlineUsers: [],
  nasDevices: [],
  logs: [],
  loading: false,
  error: null,
};

const radiusSlice = createSlice({
  name: 'radius',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const { clearError } = radiusSlice.actions;
export default radiusSlice.reducer;