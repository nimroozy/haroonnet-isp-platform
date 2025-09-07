import React from 'react';
import { Outlet } from 'react-router-dom';
import { Box, Container } from '@mui/material';

function AuthLayout() {
  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      }}
    >
      <Container>
        <Outlet />
      </Container>
    </Box>
  );
}

export default AuthLayout;