// src/components/PrivateRoute.jsx
import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function PrivateRoute({ children }) {
    const { isAuthenticated, loading } = useAuth();

    if (loading) {
        return (
            <div className="h-screen w-screen flex items-center justify-center bg-primary">
                <span className="loading loading-spinner text-accent"></span>
            </div>
        );
    }

    return isAuthenticated ? children : <Navigate to="/login" />;
}