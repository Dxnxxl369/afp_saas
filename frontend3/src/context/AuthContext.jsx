// src/context/AuthContext.jsx
import React, { createContext, useState, useEffect, useContext, useCallback } from 'react'; // <-- Añadir useCallback
import { jwtDecode } from 'jwt-decode';
import { login as apiLogin, register as apiRegister } from '../api/authService';
import { setAuthToken } from '../api/axiosConfig';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [user, setUser] = useState(null);
    const [userRoles, setUserRoles] = useState([]);
    const [userIsAdmin, setUserIsAdmin] = useState(false);
    const [loading, setLoading] = useState(true);

    const handleToken = (access_token) => {
        try {
            const decodedToken = jwtDecode(access_token);
            console.log("AuthContext: Decoded Token:", decodedToken);

            setUser({
                username: decodedToken.username,
                email: decodedToken.email,
                nombre_completo: decodedToken.nombre_completo,
                empresa_nombre: decodedToken.empresa_nombre,
                // Leer preferencias de tema del token
                theme_preference: decodedToken.theme_preference,
                theme_custom_color: decodedToken.theme_custom_color,
                theme_glow_enabled: decodedToken.theme_glow_enabled,
                empleado_id: decodedToken.empleado_id,
            });
            setUserRoles(decodedToken.roles || []);
            setUserIsAdmin(decodedToken.is_admin || false);

            localStorage.setItem('token', access_token);
            setAuthToken(access_token);
            setIsAuthenticated(true);
            console.log("AuthContext: User state set from token:", user);


        } catch (error) {
            console.error("AuthContext: Invalid token or decoding error", error);
            logout();
        }
    };

    useEffect(() => {
        console.log("AuthContext: Initializing...");
        const token = localStorage.getItem('token');
        if (token) {
            try {
                const decodedToken = jwtDecode(token);
                if (decodedToken.exp * 1000 > Date.now()) {
                    console.log("AuthContext: Found valid token in localStorage.");
                    handleToken(token);
                } else {
                    console.log("AuthContext: Found expired token.");
                    logout();
                }
            } catch (error) {
                console.log("AuthContext: Found invalid token.");
                logout();
            }
        } else {
             console.log("AuthContext: No token found.");
        }
        setLoading(false);
        console.log("AuthContext: Initialization complete. Loading:", loading);
    }, []); // <-- Quitar 'loading' de las dependencias para que corra solo una vez al montar

    const login = async (username, password) => {
        const response = await apiLogin({ username, password });
        handleToken(response.data.access);
        console.log("AuthContext: Login successful.");
    };

    const registerAndLogin = async (data) => {
        const response = await apiRegister(data);
        handleToken(response.access);
        console.log("AuthContext: Registration successful.");
    };

    const logout = () => {
        console.log("AuthContext: Logging out.");
        localStorage.removeItem('token');
        setAuthToken(null);
        setIsAuthenticated(false);
        setUser(null);
        setUserRoles([]);
        setUserIsAdmin(false);
    };

    // --- [NUEVA FUNCIÓN] ---
    // Función para actualizar SOLO las preferencias de tema en el estado 'user'
    // Usamos useCallback para que la referencia de la función no cambie innecesariamente
    const updateUserTheme = useCallback((newThemePrefs) => {
        // newThemePrefs será un objeto como { theme_preference: 'custom', ... }
        setUser(currentUser => {
            // Solo actualiza si hay un usuario actual
            if (!currentUser) return null;
            
            // Crea un nuevo objeto de usuario fusionando el actual con las nuevas preferencias
            const updatedUser = {
                ...currentUser,
                ...newThemePrefs // Sobrescribe solo los campos de tema
            };
            console.log("AuthContext: Updating user state with new theme:", updatedUser);
            return updatedUser;
        });
    }, []); // <-- Sin dependencias, setUser es estable

    // Asegúrate de pasar la nueva función en el value del Provider
    return (
        <AuthContext.Provider value={{
            isAuthenticated,
            loading,
            user,
            userRoles,
            userIsAdmin,
            login,
            logout,
            registerAndLogin,
            updateUserTheme // <-- Exportar la nueva función
        }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);