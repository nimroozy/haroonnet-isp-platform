import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// Get stored auth data
const storedAuth = localStorage.getItem('auth')
  ? JSON.parse(localStorage.getItem('auth'))
  : null;

// Configure axios defaults
if (storedAuth?.access) {
  axios.defaults.headers.common['Authorization'] = `Bearer ${storedAuth.access}`;
}

// Async thunks
export const login = createAsyncThunk(
  'auth/login',
  async ({ email, password }, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/auth/login/`, {
        email,
        password,
      });
      const { access, refresh, user } = response.data;
      
      // Set auth header
      axios.defaults.headers.common['Authorization'] = `Bearer ${access}`;
      
      // Store in localStorage
      const authData = { access, refresh, user };
      localStorage.setItem('auth', JSON.stringify(authData));
      
      return authData;
    } catch (error) {
      return rejectWithValue(error.response?.data || { detail: 'Login failed' });
    }
  }
);

export const refreshToken = createAsyncThunk(
  'auth/refresh',
  async (_, { getState, rejectWithValue }) => {
    try {
      const { auth } = getState();
      const response = await axios.post(`${API_URL}/auth/refresh/`, {
        refresh: auth.refresh,
      });
      
      const { access } = response.data;
      
      // Update auth header
      axios.defaults.headers.common['Authorization'] = `Bearer ${access}`;
      
      // Update localStorage
      const authData = { ...auth, access };
      localStorage.setItem('auth', JSON.stringify(authData));
      
      return { access };
    } catch (error) {
      return rejectWithValue(error.response?.data || { detail: 'Token refresh failed' });
    }
  }
);

export const logout = createAsyncThunk('auth/logout', async () => {
  // Clear auth header
  delete axios.defaults.headers.common['Authorization'];
  
  // Clear localStorage
  localStorage.removeItem('auth');
  
  return null;
});

export const updateProfile = createAsyncThunk(
  'auth/updateProfile',
  async (profileData, { rejectWithValue }) => {
    try {
      const response = await axios.patch(`${API_URL}/accounts/profile/`, profileData);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data || { detail: 'Profile update failed' });
    }
  }
);

// Initial state
const initialState = {
  user: storedAuth?.user || null,
  access: storedAuth?.access || null,
  refresh: storedAuth?.refresh || null,
  isAuthenticated: !!storedAuth?.access,
  loading: false,
  error: null,
};

// Slice
const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    updateUser: (state, action) => {
      state.user = { ...state.user, ...action.payload };
    },
  },
  extraReducers: (builder) => {
    builder
      // Login
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.isAuthenticated = true;
        state.user = action.payload.user;
        state.access = action.payload.access;
        state.refresh = action.payload.refresh;
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
        state.isAuthenticated = false;
      })
      // Refresh token
      .addCase(refreshToken.fulfilled, (state, action) => {
        state.access = action.payload.access;
      })
      .addCase(refreshToken.rejected, (state) => {
        state.isAuthenticated = false;
        state.user = null;
        state.access = null;
        state.refresh = null;
      })
      // Logout
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.access = null;
        state.refresh = null;
        state.isAuthenticated = false;
      })
      // Update profile
      .addCase(updateProfile.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateProfile.fulfilled, (state, action) => {
        state.loading = false;
        state.user = { ...state.user, ...action.payload };
      })
      .addCase(updateProfile.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { clearError, updateUser } = authSlice.actions;
export default authSlice.reducer;

// Selectors
export const selectAuth = (state) => state.auth;
export const selectUser = (state) => state.auth.user;
export const selectIsAuthenticated = (state) => state.auth.isAuthenticated;