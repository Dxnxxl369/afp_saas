/*// src/App.jsx
import React from 'react';
import { ThemeProvider } from './context/ThemeContext';
import { AuthProvider, useAuth } from './context/AuthContext'; // <-- Importamos el Auth
import Layout from './components/Layout';
import { NotificationProvider } from './context/NotificacionContext';
import LoginPage from './pages/login/LoginPage'; // <-- Crearemos esta página

// Componente intermedio que decide qué mostrar: Login o el Layout principal
const AppContent = () => {
    const { isAuthenticated, loading } = useAuth();

    if (loading) {
        // Muestra un loader mientras se verifica si hay un token guardado
        return (
            <div className="h-screen w-screen flex items-center justify-center bg-primary">
                <span className="loading loading-spinner text-accent"></span>
            </div>
        );
    }

    return isAuthenticated ? <Layout /> : <LoginPage />;
};

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <NotificationProvider>
          <AppContent />
        </NotificationProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}*/

/*// src/App.jsx
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import { AuthProvider } from './context/AuthContext';
import { NotificationProvider } from './context/NotificacionContext';

// Importaciones de Páginas
import Layout from './components/Layout';
import PrivateRoute from './components/PrivateRoute';
import LoginPage from './pages/login/LoginPage';
import SubscriptionPage from './pages/public/SubscriptionPage';
import PaymentPage from './pages/public/PaymentPage';

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <NotificationProvider>
          <BrowserRouter>
            <Routes>              
              <Route path="/" element={<Navigate to="/subscribe" />} />
              <Route path="/subscribe" element={<SubscriptionPage />} />
              <Route path="/payment" element={<PaymentPage />} />
              <Route path="/login" element={<LoginPage />} />              
              <Route 
                path="/app" 
                element={
                  <PrivateRoute>
                    <Layout />
                  </PrivateRoute>
                } 
              />                            
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </BrowserRouter>
        </NotificationProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}*/
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