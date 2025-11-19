
// src/App.jsx
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

// No necesitas importar los providers aquí

// Importaciones de Páginas
import Layout from './components/Layout';
import PrivateRoute from './components/PrivateRoute';
import LoginPage from './pages/login/LoginPage';
import SubscriptionPage from './pages/public/SubscriptionPage';
import PaymentPage from './pages/public/PaymentPage';

export default function App() {
  // Ya no necesitamos los wrappers de Providers aquí
  return (
    <BrowserRouter>
      <Routes>
        {/* Rutas Públicas */}
        <Route path="/" element={<Navigate to="/subscribe" />} />
        <Route path="/subscribe" element={<SubscriptionPage />} />
        <Route path="/payment" element={<PaymentPage />} />
        <Route path="/login" element={<LoginPage />} />

        {/* Ruta Privada para la App Principal */}
        <Route
          path="/app"
          element={
            <PrivateRoute>
              <Layout />
            </PrivateRoute>
          }
        />
        {/* Ruta para cualquier otra URL no definida */}
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}